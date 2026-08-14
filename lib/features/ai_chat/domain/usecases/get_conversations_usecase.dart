import '../../../../core/utils/result.dart';
import '../entities/conversation.dart';
import '../repositories/conversation_repository.dart';

class GetConversationsUseCase {
  final ConversationRepository _repo;
  GetConversationsUseCase(this._repo);

  Future<Result<List<Conversation>>> call({bool includeArchived = false, String? projectId}) {
    return _repo.listConversations(includeArchived: includeArchived, projectId: projectId);
  }
}
