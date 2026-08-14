import '../../../../core/utils/result.dart';
import '../entities/conversation.dart';

abstract class ConversationRepository {
  Future<Result<Conversation>> createConversation(Conversation conversation);
  Future<Result<Conversation>> getConversation(String id);
  Future<Result<List<Conversation>>> listConversations({bool includeArchived = false, String? projectId});
  Future<Result<Conversation>> updateConversation(Conversation conversation);
  Future<Result<void>> deleteConversation(String id);
  Future<Result<Conversation>> archiveConversation(String id, bool archived);
  Future<Result<List<Conversation>>> searchConversations(String query);
}
