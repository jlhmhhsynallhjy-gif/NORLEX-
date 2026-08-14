
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database/app_database.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/ai/ai_service.dart';
import '../../../core/network/network_info.dart';
import '../data/local/chat_local_data_source.dart';
import '../data/repositories/conversation_repository_impl.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/repositories/conversation_repository.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/create_conversation_usecase.dart';
import '../domain/usecases/get_conversations_usecase.dart';
import '../domain/usecases/send_message_usecase.dart';
import '../domain/entities/conversation.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/chat_enums.dart';
import '../domain/entities/model_config.dart';
import '../domain/entities/chat_context.dart';
import '../../../core/utils/result.dart';

final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return ChatLocalDataSource(db);
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(ref.watch(chatLocalDataSourceProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    ref.watch(chatLocalDataSourceProvider),
    ref.watch(aiGatewayProvider),
  );
});

final createConversationUseCaseProvider = Provider<CreateConversationUseCase>((ref) {
  return CreateConversationUseCase(ref.watch(conversationRepositoryProvider));
});

final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>((ref) {
  return GetConversationsUseCase(ref.watch(conversationRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final usecase = ref.watch(getConversationsUseCaseProvider);
  final result = await usecase.call();
  if (result is Success<List<Conversation>>) return result.data;
  return [];
});

final conversationsSearchProvider = StateProvider<String>((ref) => '');

final filteredConversationsProvider = Provider<AsyncValue<List<Conversation>>>((ref) {
  final asyncConvs = ref.watch(conversationsProvider);
  final query = ref.watch(conversationsSearchProvider).toLowerCase();
  return asyncConvs.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((c) => c.title.toLowerCase().contains(query)).toList();
  });
});

class ChatState {
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? streamingMessageId;
  final String? error;
  final ModelConfig selectedModel;
  const ChatState({this.conversation, this.messages = const [], this.isLoading = false, this.isStreaming = false, this.streamingMessageId, this.error, required this.selectedModel});
  ChatState copyWith({Conversation? conversation, List<ChatMessage>? messages, bool? isLoading, bool? isStreaming, String? streamingMessageId, String? error, ModelConfig? selectedModel}) {
    return ChatState(conversation: conversation ?? this.conversation, messages: messages ?? this.messages, isLoading: isLoading ?? this.isLoading, isStreaming: isStreaming ?? this.isStreaming, streamingMessageId: streamingMessageId ?? this.streamingMessageId, error: error, selectedModel: selectedModel ?? this.selectedModel);
  }
}

final defaultModelProvider = Provider<ModelConfig>((ref) {
  return const ModelConfig(providerId: 'norlex_backend', modelId: 'norlex-default', displayName: 'NORLEX Default', contextWindow: 8192, supportsStreaming: true);
});

final chatControllerProvider = StateNotifierProvider.family<ChatController, ChatState, String>((ref, conversationId) {
  final controller = ChatController(ref, conversationId);
  ref.onDispose(() { controller.disposeController(); });
  return controller;
});

class ChatController extends StateNotifier<ChatState> {
  final Ref _ref;
  final String _conversationId;
  bool _isDisposed = false;
  StreamSubscription? _currentSendSubscription;
  ChatController(this._ref, this._conversationId) : super(ChatState(selectedModel: _ref.read(defaultModelProvider))) { _loadConversation(); }
  void _safeUpdate(ChatState Function() updater) { if (_isDisposed) return; if (!mounted) return; state = updater(); }
  Future<void> _loadConversation() async {
    _safeUpdate(() => state.copyWith(isLoading: true));
    final convRepo = _ref.read(conversationRepositoryProvider);
    final chatRepo = _ref.read(chatRepositoryProvider);
    final convResult = await convRepo.getConversation(_conversationId);
    final msgsResult = await chatRepo.getMessages(_conversationId);
    if (_isDisposed) return;
    if (convResult is Success<Conversation> && msgsResult is Success<List<ChatMessage>>) {
      _safeUpdate(() => state.copyWith(conversation: convResult.data, messages: msgsResult.data, isLoading: false));
    } else {
      _safeUpdate(() => state.copyWith(isLoading: false, error: 'Failed to load conversation'));
    }
  }
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state.isStreaming) return;
    if (_isDisposed) return;
    try {
      final networkInfo = _ref.read(networkInfoProvider);
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        _safeUpdate(() => state.copyWith(error: 'No internet connection. Message will be saved for retry.'));
        final conv = state.conversation;
        if (conv != null) {
          final chatRepo = _ref.read(chatRepositoryProvider);
          final userMsg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), conversationId: _conversationId, role: MessageRole.user, content: content, createdAt: DateTime.now(), status: MessageStatus.completed);
          await chatRepo.addMessage(userMsg);
          final msgsResult = await chatRepo.getMessages(_conversationId);
          if (msgsResult is Success<List<ChatMessage>> && !_isDisposed) { _safeUpdate(() => state.copyWith(messages: msgsResult.data)); }
        }
        return;
      }
    } catch (_) {}
    final chatRepo = _ref.read(chatRepositoryProvider);
    final conv = state.conversation;
    if (conv == null) return;
    final context = ChatContext(conversation: conv, relevantMessages: state.messages.length > 20 ? state.messages.sublist(state.messages.length - 20) : state.messages);
    _safeUpdate(() => state.copyWith(isStreaming: true, error: null));
    final stream = chatRepo.sendMessageStream(context: context, userMessageContent: content, modelConfig: state.selectedModel);
    _currentSendSubscription = stream.listen((result) {
      if (_isDisposed) return;
      if (result is Success<ChatMessage>) {
        final msg = result.data;
        final existingIndex = state.messages.indexWhere((m) => m.id == msg.id);
        List<ChatMessage> updated;
        if (existingIndex >= 0) { updated = [...state.messages]; updated[existingIndex] = msg; } else { updated = [...state.messages, msg]; }
        updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _safeUpdate(() => state.copyWith(messages: updated, streamingMessageId: msg.isStreaming ? msg.id : null));
      } else if (result is FailureResult<ChatMessage>) {
        _safeUpdate(() => state.copyWith(error: result.failure.message));
      }
    }, onError: (e) { if (!_isDisposed) _safeUpdate(() => state.copyWith(isStreaming: false, error: e.toString())); }, onDone: () { if (!_isDisposed) _safeUpdate(() => state.copyWith(isStreaming: false, streamingMessageId: null)); });
    await _currentSendSubscription?.asFuture();
    _currentSendSubscription = null;
    if (_isDisposed) return;
    final msgsResult = await chatRepo.getMessages(_conversationId);
    if (msgsResult is Success<List<ChatMessage>>) { _safeUpdate(() => state.copyWith(messages: msgsResult.data, isStreaming: false)); }
  }
  Future<void> cancelGeneration() async {
    await _currentSendSubscription?.cancel();
    _currentSendSubscription = null;
    final chatRepo = _ref.read(chatRepositoryProvider);
    await chatRepo.cancelGeneration(_conversationId);
    if (!_isDisposed) { _safeUpdate(() => state.copyWith(isStreaming: false, streamingMessageId: null)); }
  }
  Future<void> retryMessage(String messageId) async {
    if (state.isStreaming) return;
    final chatRepo = _ref.read(chatRepositoryProvider);
    final result = await chatRepo.retryMessage(messageId);
    if (result is Success<ChatMessage> && !_isDisposed) { await sendMessage(result.data.content); }
  }
  Future<void> regenerateLast() async {
    if (state.isStreaming) return;
    final chatRepo = _ref.read(chatRepositoryProvider);
    final result = await chatRepo.regenerateLastAssistantMessage(_conversationId, state.selectedModel);
    if (result is Success<ChatMessage> && !_isDisposed) { await sendMessage(result.data.content); }
  }
  Future<void> deleteMessage(String messageId) async {
    final chatRepo = _ref.read(chatRepositoryProvider);
    await chatRepo.deleteMessage(messageId);
    if (!_isDisposed) { _safeUpdate(() => state.copyWith(messages: state.messages.where((m) => m.id != messageId).toList())); }
  }
  void selectModel(ModelConfig config) { if (!_isDisposed) _safeUpdate(() => state.copyWith(selectedModel: config)); }
  void disposeController() {
    _isDisposed = true;
    _currentSendSubscription?.cancel();
    _currentSendSubscription = null;
    try { final chatRepo = _ref.read(chatRepositoryProvider); chatRepo.cancelGeneration(_conversationId); } catch (_) {}
  }
  @override
  void dispose() { disposeController(); super.dispose(); }
}
