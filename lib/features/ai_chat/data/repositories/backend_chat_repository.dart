import 'dart:async';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_enums.dart';
import '../../domain/entities/chat_context.dart';
import '../../domain/entities/model_config.dart';
import '../../domain/repositories/chat_repository.dart';
import '../local/chat_local_data_source.dart';
import '../remote/backend_api.dart';
import '../../../../core/ai/gateway/ai_gateway.dart';
import '../../../../core/ai/providers/ai_provider.dart';

/// Hybrid Repository: Tries Backend first, falls back to local foundation if backend unavailable
/// This keeps app working in foundation mode when backend not available

class BackendChatRepository implements ChatRepository {
  final ChatLocalDataSource _local;
  final BackendApi _backendApi;
  final AiGateway _gateway; // Fallback

  final Map<String, bool> _isGenerating = {};

  BackendChatRepository(this._local, this._backendApi, this._gateway);

  @override
  Future<Result<ChatMessage>> addMessage(ChatMessage message) async {
    try {
      await _local.insertMessage(message);
      await _local.updateConversationTimestamp(message.conversationId);
      return Success(message);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages(String conversationId, {int limit = 100, int offset = 0}) async {
    try {
      final msgs = await _local.getMessages(conversationId, limit: limit, offset: offset);
      return Success(msgs);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    try {
      await _local.deleteMessage(messageId);
      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ChatMessage>> updateMessage(ChatMessage message) async {
    try {
      await _local.insertMessage(message);
      return Success(message);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Result<ChatMessage>> sendMessageStream({
    required ChatContext context,
    required String userMessageContent,
    required ModelConfig modelConfig,
  }) async* {
    final conversationId = context.conversation.id;
    if (_isGenerating[conversationId] == true) {
      yield const FailureResult(ServerFailure('Already generating', code: 'concurrent_generation'));
      return;
    }
    _isGenerating[conversationId] = true;

    try {
      // Save user message locally first (offline-first)
      final userMsg = ChatMessage(
        id: UuidGenerator.v4(),
        conversationId: conversationId,
        role: MessageRole.user,
        content: userMessageContent,
        createdAt: DateTime.now(),
        status: MessageStatus.completed,
      );
      await _local.insertMessage(userMsg);
      yield Success(userMsg);

      // Assistant placeholder streaming
      var assistantId = UuidGenerator.v4();
      var assistantMsg = ChatMessage(
        id: assistantId,
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: '',
        createdAt: DateTime.now(),
        status: MessageStatus.streaming,
        modelId: modelConfig.modelId,
        providerId: modelConfig.providerId,
      );
      await _local.insertMessage(assistantMsg);
      yield Success(assistantMsg);

      // Try Backend API first
      try {
        final messagesPayload = [
          ...context.relevantMessages.map((m) => {'role': m.role.name, 'content': m.content}),
          {'role': 'user', 'content': userMessageContent},
        ];

        String accumulated = '';
        // Attempt backend streaming
        final backendStream = _backendApi.streamChat(
          modelId: modelConfig.modelId,
          messages: messagesPayload,
          conversationId: conversationId,
        );

        bool gotBackendResponse = false;
        await for (final result in backendStream) {
          if (result is Success<String>) {
            gotBackendResponse = true;
            accumulated += result.data;
            assistantMsg = assistantMsg.copyWith(content: accumulated, status: MessageStatus.streaming);
            await _local.insertMessage(assistantMsg);
            yield Success(assistantMsg);
          }
        }

        if (gotBackendResponse) {
          assistantMsg = assistantMsg.copyWith(status: MessageStatus.completed, content: accumulated);
          await _local.insertMessage(assistantMsg);
          await _local.updateConversationTimestamp(conversationId);
          yield Success(assistantMsg);
          return;
        }
        // If no backend response, fall through to gateway fallback
      } catch (_) {
        // Backend not available - fallback to gateway (which will give honest provider_unavailable)
      }

      // Fallback to local gateway - will return provider_unavailable honestly
      final aiRequest = AiRequest(
        prompt: userMessageContent,
        modelId: modelConfig.modelId,
      );

      try {
        String accumulated = '';
        await for (final aiChunk in _gateway.streamComplete(aiRequest)) {
          if (aiChunk.type == 'error') {
            assistantMsg = assistantMsg.copyWith(
              status: MessageStatus.failed,
              metadata: {'code': aiChunk.error_code, 'error': aiChunk.error_message},
            );
            await _local.insertMessage(assistantMsg);
            yield Success(assistantMsg);
            yield FailureResult(ServerFailure(aiChunk.error_message ?? 'Provider unavailable', code: aiChunk.error_code));
            return;
          }
          if (aiChunk.content != null) {
            accumulated += aiChunk.content!;
            assistantMsg = assistantMsg.copyWith(content: accumulated, status: aiChunk.type == 'completed' ? MessageStatus.completed : MessageStatus.streaming);
            await _local.insertMessage(assistantMsg);
            yield Success(assistantMsg);
          }
        }
        assistantMsg = assistantMsg.copyWith(status: MessageStatus.completed);
        await _local.insertMessage(assistantMsg);
        await _local.updateConversationTimestamp(conversationId);
        yield Success(assistantMsg);
      } on UnimplementedError {
        assistantMsg = assistantMsg.copyWith(
          status: MessageStatus.failed,
          metadata: {'code': 'provider_unavailable', 'error': 'Backend not configured - foundation mode'},
        );
        await _local.insertMessage(assistantMsg);
        yield Success(assistantMsg);
        yield const FailureResult(ServerFailure('AI provider not configured. Backend gateway required.', code: 'provider_unavailable'));
      }
    } finally {
      _isGenerating[conversationId] = false;
    }
  }

  @override
  Future<Result<ChatMessage>> retryMessage(String messageId) async {
    final msg = await _local.getMessage(messageId);
    if (msg == null) return const FailureResult(CacheFailure('Message not found'));
    if (msg.role == MessageRole.assistant) {
      final lastUser = await _local.getLastUserMessage(msg.conversationId);
      if (lastUser == null) return const FailureResult(CacheFailure('No user message'));
      return Success(lastUser);
    }
    return Success(msg);
  }

  @override
  Future<Result<ChatMessage>> regenerateLastAssistantMessage(String conversationId, ModelConfig modelConfig) async {
    final messages = await _local.getMessages(conversationId, limit: 100);
    final lastAssistantIndex = messages.lastIndexWhere((m) => m.role == MessageRole.assistant);
    if (lastAssistantIndex == -1) return const FailureResult(CacheFailure('No assistant message'));
    final lastAssistant = messages[lastAssistantIndex];
    await _local.deleteMessage(lastAssistant.id);
    final lastUser = await _local.getLastUserMessage(conversationId);
    if (lastUser == null) return const FailureResult(CacheFailure('No user message'));
    return Success(lastUser);
  }

  @override
  Future<void> cancelGeneration(String conversationId) async {
    _isGenerating[conversationId] = false;
  }
}
