import '../../../../core/utils/result.dart';
import '../entities/chat_message.dart';
import '../entities/chat_context.dart';
import '../entities/model_config.dart';

abstract class ChatRepository {
  Future<Result<ChatMessage>> addMessage(ChatMessage message);
  Future<Result<List<ChatMessage>>> getMessages(String conversationId, {int limit = 100, int offset = 0});
  Future<Result<void>> deleteMessage(String messageId);
  Future<Result<ChatMessage>> updateMessage(ChatMessage message);
  
  // AI operations - must go through AI Service
  Stream<Result<ChatMessage>> sendMessageStream({
    required ChatContext context,
    required String userMessageContent,
    required ModelConfig modelConfig,
  });

  Future<Result<ChatMessage>> retryMessage(String messageId);
  Future<Result<ChatMessage>> regenerateLastAssistantMessage(String conversationId, ModelConfig modelConfig);
  
  // Cancellation
  Future<void> cancelGeneration(String conversationId);
}
