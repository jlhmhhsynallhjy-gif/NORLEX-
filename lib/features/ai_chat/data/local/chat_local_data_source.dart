import 'package:drift/drift.dart';
import '../../../../data/local/database/app_database.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/chat_message.dart';
import 'mappers/conversation_mapper.dart';
import 'mappers/message_mapper.dart';
import 'tables/conversations_table.dart';
import 'tables/chat_messages_table.dart';
import 'tables/chat_attachments_table.dart';

class ChatLocalDataSource {
  final AppDatabase db;
  ChatLocalDataSource(this.db);

  // Conversations
  Future<void> insertConversation(Conversation conv) async {
    await db.into(db.conversationsTable).insertOnConflictUpdate(ConversationMapper.toCompanion(conv));
  }

  Future<Conversation?> getConversation(String id) async {
    final row = await (db.select(db.conversationsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return ConversationMapper.fromTable(row);
  }

  Future<List<Conversation>> listConversations({bool includeArchived = false, String? projectId}) async {
    var query = db.select(db.conversationsTable);
    if (!includeArchived) {
      query = query..where((t) => t.archived.equals(false));
    }
    if (projectId != null) {
      query = query..where((t) => t.projectId.equals(projectId));
    }
    query = query..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    final rows = await query.get();
    return rows.map(ConversationMapper.fromTable).toList();
  }

  Future<List<Conversation>> searchConversations(String q) async {
    final rows = await (db.select(db.conversationsTable)..where((t) => t.title.like('%\$q%'))..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    return rows.map(ConversationMapper.fromTable).toList();
  }

  Future<void> deleteConversation(String id) async {
    await (db.delete(db.conversationsTable)..where((t) => t.id.equals(id))).go();
    // cascade delete messages
    await (db.delete(db.chatMessagesTable)..where((t) => t.conversationId.equals(id))).go();
  }

  // Messages
  Future<void> insertMessage(ChatMessage msg) async {
    await db.into(db.chatMessagesTable).insertOnConflictUpdate(MessageMapper.toCompanion(msg));
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {int limit = 100, int offset = 0}) async {
    final query = (db.select(db.chatMessagesTable)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(limit, offset: offset));
    final rows = await query.get();
    return rows.map(MessageMapper.fromTable).toList();
  }

  Future<ChatMessage?> getMessage(String id) async {
    final row = await (db.select(db.chatMessagesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return MessageMapper.fromTable(row);
  }

  Future<void> deleteMessage(String id) async {
    await (db.delete(db.chatMessagesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateConversationTimestamp(String conversationId) async {
    await (db.update(db.conversationsTable)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTableCompanion(updatedAt: Value(DateTime.now())),
    );
  }
}
