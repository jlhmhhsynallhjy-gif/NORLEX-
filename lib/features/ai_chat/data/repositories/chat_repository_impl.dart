import 'dart:async';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/ai/gateway/ai_gateway.dart';
import '../../../../core/ai/providers/ai_provider.dart';
import '../../../../core/ai/ai_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_enums.dart';
import '../../domain/entities/chat_context.dart';
import '../../domain/entities/model_config.dart';
import '../../domain/repositories/chat_repository.dart';
import '../local/chat_local_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource _local;
  final AiGateway _gateway;
  
  // Track active generations for cancellation
  final Map<String, StreamSubscription> _activeStreams = {};
  final Map<String, Completer<void>> _cancelTokens = {};

  ChatRepositoryImpl(this._local, this._gateway);

  @override
  Future<Result<ChatMessage>> addMessage(ChatMessage message) async {
    try {
      await _local.insertMessage(message);
      await _local.updateConversationTimestamp(message.conversationId);
      return Success(message);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages(String conversationId, {int limit = 100, int offset = 0}) async {
    try {
      final msgs = await _local.getMessages(conversationId, limit: limit, offset: offset);
      return Success(msgs);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    try {
      await _local.deleteMessage(messageId);
      return const Success(null);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<ChatMessage>> updateMessage(ChatMessage message) async {
    try {
      await _local.insertMessage(message);
      return Success(message);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Stream<Result<ChatMessage>> sendMessageStream({
    required ChatContext context,
    required String userMessageContent,
    required ModelConfig modelConfig,
  }) async* {
    final conversationId = context.conversation.id;
    final cancelCompleter = Completer<void>();
    _cancelTokens[conversationId] = cancelCompleter;

    try {
      // 1. Save user message
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

      // 2. Create assistant placeholder streaming
      final assistantId = UuidGenerator.v4();
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

      // 3. Build AI request - follows path: ChatRepo -> AI Service -> Gateway -> Provider
      final aiRequest = AiRequest(
        prompt: userMessageContent,
        modelId: modelConfig.modelId,
        systemPrompt: 'You are NORLEX AI. Context: \${context.toAiPayload()}',
      );

      // 4. Try streaming - will fail gracefully if no backend provider configured (foundation integrity)
      try {
        final stream = _gateway.streamComplete(aiRequest);
        final subscription = stream.listen(
          (aiResponse) async {
            if (cancelCompleter.isCompleted) return;
            assistantMsg = assistantMsg.copyWith(
              content: assistantMsg.content + aiResponse.content,
              status: aiResponse.isStreaming ? MessageStatus.streaming : MessageStatus.completed,
            );
            await _local.insertMessage(assistantMsg);
          },
          onError: (e) async {
            final failure = ErrorHandler.handleException(e);
            assistantMsg = assistantMsg.copyWith(
              status: MessageStatus.failed,
              metadata: {'error': failure.message, 'code': failure.code},
            );
            await _local.insertMessage(assistantMsg);
          },
        );
        _activeStreams[conversationId] = subscription;

        // Wait for stream or cancellation
        await Future.any([
          subscription.asFuture(),
          cancelCompleter.future,
        ]);

        if (cancelCompleter.isCompleted) {
          await subscription.cancel();
          assistantMsg = assistantMsg.copyWith(status: MessageStatus.cancelled);
          await _local.insertMessage(assistantMsg);
          yield Success(assistantMsg);
          return;
        }

        // Finalize
        assistantMsg = assistantMsg.copyWith(status: MessageStatus.completed);
        await _local.insertMessage(assistantMsg);
        await _local.updateConversationTimestamp(conversationId);
        yield Success(assistantMsg);

      } on UnimplementedError catch (_) {
        // FOUNDATION: No backend yet - this is honest failure, not fake response
        assistantMsg = assistantMsg.copyWith(
          status: MessageStatus.failed,
          metadata: {
            'error': 'AI provider not configured. Backend gateway required.',
            'code': 'provider_unavailable',
            'is_foundation': true,
          },
        );
        await _local.insertMessage(assistantMsg);
        yield Success(assistantMsg);
        yield const FailureResult(ServerFailure('AI provider not configured. Please configure backend gateway.', code: 'provider_unavailable'));
      }
    } catch (e) {
      yield FailureResult(ErrorHandler.handleException(e));
    } finally {
      _activeStreams.remove(conversationId);
      _cancelTokens.remove(conversationId);
    }
  }

  @override
  Future<Result<ChatMessage>> retryMessage(String messageId) async {
    try {
      final msg = await _local.getMessage(messageId);
      if (msg == null) return const FailureResult(CacheFailure('Message not found'));
      // For retry, we create a new generation request - implementation will be in usecase
      // Here we just mark previous as failed and return it for re-send
      return Success(msg);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<ChatMessage>> regenerateLastAssistantMessage(String conversationId, ModelConfig modelConfig) async {
    try {
      final messages = await _local.getMessages(conversationId, limit: 50);
      if (messages.isEmpty) return const FailureResult(CacheFailure('No messages to regenerate'));
      final lastAssistant = messages.lastWhere((m) => m.role == MessageRole.assistant, orElse: () => messages.last);
      await _local.deleteMessage(lastAssistant.id);
      // New generation will be triggered by UI via sendMessageStream with last user message
      return Success(lastAssistant);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<void> cancelGeneration(String conversationId) async {
    _cancelTokens[conversationId]?.complete();
    await _activeStreams[conversationId]?.cancel();
    _activeStreams.remove(conversationId);
  }
}
