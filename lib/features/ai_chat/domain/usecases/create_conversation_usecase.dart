import '../../../../core/utils/result.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../entities/conversation.dart';
import '../repositories/conversation_repository.dart';

class CreateConversationUseCase {
  final ConversationRepository _repo;
  CreateConversationUseCase(this._repo);

  Future<Result<Conversation>> call({required String userId, String? projectId, String? title}) async {
    final now = DateTime.now();
    final conv = Conversation(
      id: UuidGenerator.v4(),
      userId: userId,
      projectId: projectId,
      title: title ?? 'New Chat',
      createdAt: now,
      updatedAt: now,
    );
    return _repo.createConversation(conv);
  }
}
