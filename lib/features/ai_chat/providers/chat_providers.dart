import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database/app_database.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/ai/ai_service.dart';
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
import '../domain/entities/model_config.dart';
import '../domain/entities/chat_context.dart';
import '../../../core/utils/result.dart';

// Data source
final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return ChatLocalDataSource(db);
});

// Repositories
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(ref.watch(chatLocalDataSourceProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    ref.watch(chatLocalDataSourceProvider),
    ref.watch(aiGatewayProvider),
  );
});

// Usecases
final createConversationUseCaseProvider = Provider<CreateConversationUseCase>((ref) {
  return CreateConversationUseCase(ref.watch(conversationRepositoryProvider));
});

final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>((ref) {
  return GetConversationsUseCase(ref.watch(conversationRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

// Conversation list
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

// Chat state
class ChatState {
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? streamingMessageId;
  final String? error;
  final ModelConfig selectedModel;

  const ChatState({
    this.conversation,
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.streamingMessageId,
    this.error,
    required this.selectedModel,
  });

  ChatState copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? streamingMessageId,
    String? error,
    ModelConfig? selectedModel,
  }) {
    return ChatState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingMessageId: streamingMessageId ?? this.streamingMessageId,
      error: error,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }
}

final defaultModelProvider = Provider<ModelConfig>((ref) {
  return const ModelConfig(
    providerId: 'norlex_backend',
    modelId: 'norlex-default',
    displayName: 'NORLEX Default',
    contextWindow: 8192,
    supportsStreaming: true,
  );
});

final chatControllerProvider = StateNotifierProvider.family<ChatController, ChatState, String>((ref, conversationId) {
  return ChatController(ref, conversationId);
});

class ChatController extends StateNotifier<ChatState> {
  final Ref _ref;
  final String _conversationId;

  ChatController(this._ref, this._conversationId) : super(ChatState(selectedModel: _ref.read(defaultModelProvider))) {
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    state = state.copyWith(isLoading: true);
    final convRepo = _ref.read(conversationRepositoryProvider);
    final chatRepo = _ref.read(chatRepositoryProvider);

    final convResult = await convRepo.getConversation(_conversationId);
    final msgsResult = await chatRepo.getMessages(_conversationId);

    if (convResult is Success<Conversation> && msgsResult is Success<List<ChatMessage>>) {
      state = state.copyWith(
        conversation: convResult.data,
        messages: msgsResult.data,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false, error: 'Failed to load conversation');
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isStreaming) return;

    final chatRepo = _ref.read(chatRepositoryProvider);
    final conv = state.conversation;
    if (conv == null) return;

    final context = ChatContext(
      conversation: conv,
      relevantMessages: state.messages.length > 20 ? state.messages.sublist(state.messages.length - 20) : state.messages,
    );

    state = state.copyWith(isStreaming: true, error: null);

    final stream = chatRepo.sendMessageStream(
      context: context,
      userMessageContent: content,
      modelConfig: state.selectedModel,
    );

    await for (final result in stream) {
      if (result is Success<ChatMessage>) {
        final msg = result.data;
        // Update messages list
        final existingIndex = state.messages.indexWhere((m) => m.id == msg.id);
        List<ChatMessage> updated;
        if (existingIndex >= 0) {
          updated = [...state.messages];
          updated[existingIndex] = msg;
        } else {
          updated = [...state.messages, msg];
        }
        // Sort by createdAt
        updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = state.copyWith(messages: updated, streamingMessageId: msg.isStreaming ? msg.id : null);
      } else if (result is FailureResult<ChatMessage>) {
        state = state.copyWith(error: result.failure.message, isStreaming: false);
      }
    }

    state = state.copyWith(isStreaming: false, streamingMessageId: null);
    // Reload to ensure persistence
    final msgsResult = await chatRepo.getMessages(_conversationId);
    if (msgsResult is Success<List<ChatMessage>>) {
      state = state.copyWith(messages: msgsResult.data);
    }
  }

  Future<void> cancelGeneration() async {
    final chatRepo = _ref.read(chatRepositoryProvider);
    await chatRepo.cancelGeneration(_conversationId);
    state = state.copyWith(isStreaming: false);
  }

  Future<void> retryMessage(String messageId) async {
    final chatRepo = _ref.read(chatRepositoryProvider);
    final result = await chatRepo.retryMessage(messageId);
    if (result is Success<ChatMessage>) {
      // Re-send last user message
      final lastUser = state.messages.lastWhere((m) => m.role.name == 'user', orElse: () => result.data);
      await sendMessage(lastUser.content);
    }
  }

  Future<void> regenerateLast() async {
    final chatRepo = _ref.read(chatRepositoryProvider);
    await chatRepo.regenerateLastAssistantMessage(_conversationId, state.selectedModel);
    // Find last user message and re-send
    final lastUser = state.messages.lastWhere((m) => m.role.name == 'user', orElse: () => state.messages.last);
    await sendMessage(lastUser.content);
  }

  Future<void> deleteMessage(String messageId) async {
    final chatRepo = _ref.read(chatRepositoryProvider);
    await chatRepo.deleteMessage(messageId);
    state = state.copyWith(messages: state.messages.where((m) => m.id != messageId).toList());
  }

  void selectModel(ModelConfig config) {
    state = state.copyWith(selectedModel: config);
  }
}
