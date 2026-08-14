import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_context.dart';
import '../entities/model_config.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _chatRepo;
  SendMessageUseCase(this._chatRepo);

  Stream<Result<dynamic>> call({
    required ChatContext context,
    required String content,
    required ModelConfig modelConfig,
  }) {
    if (content.trim().isEmpty) {
      return Stream.value(const FailureResult(ValidationFailure('Message cannot be empty')));
    }
    return _chatRepo.sendMessageStream(
      context: context,
      userMessageContent: content,
      modelConfig: modelConfig,
    );
  }
}
