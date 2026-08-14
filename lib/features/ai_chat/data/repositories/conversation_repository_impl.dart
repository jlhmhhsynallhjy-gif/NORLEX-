import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/error_handler.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../local/chat_local_data_source.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final ChatLocalDataSource _local;
  ConversationRepositoryImpl(this._local);

  @override
  Future<Result<Conversation>> createConversation(Conversation conversation) async {
    try {
      await _local.insertConversation(conversation);
      return Success(conversation);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deleteConversation(String id) async {
    try {
      await _local.deleteConversation(id);
      return const Success(null);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<Conversation>> getConversation(String id) async {
    try {
      final conv = await _local.getConversation(id);
      if (conv == null) return const FailureResult(CacheFailure('Conversation not found'));
      return Success(conv);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<Conversation>>> listConversations({bool includeArchived = false, String? projectId}) async {
    try {
      final list = await _local.listConversations(includeArchived: includeArchived, projectId: projectId);
      return Success(list);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<Conversation>>> searchConversations(String query) async {
    try {
      if (query.trim().isEmpty) return const Success([]);
      final list = await _local.searchConversations(query);
      return Success(list);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<Conversation>> archiveConversation(String id, bool archived) async {
    try {
      final conv = await _local.getConversation(id);
      if (conv == null) return const FailureResult(CacheFailure('Conversation not found'));
      final updated = conv.copyWith(archived: archived, updatedAt: DateTime.now());
      await _local.insertConversation(updated);
      return Success(updated);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<Conversation>> updateConversation(Conversation conversation) async {
    try {
      final updated = conversation.copyWith(updatedAt: DateTime.now());
      await _local.insertConversation(updated);
      return Success(updated);
    } catch (e) {
      return FailureResult(ErrorHandler.handleException(e));
    }
  }
}
