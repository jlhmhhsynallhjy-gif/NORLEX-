import 'package:drift/drift.dart';
import '../../../../data/local/database/app_database.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/chat_message.dart';
import 'mappers/conversation_mapper.dart';
import 'mappers/message_mapper.dart';
import 'tables/conversations_table.dart';
import 'tables/chat_messages_table.dart';

class ChatLocalDataSource {
  final AppDatabase db;
  ChatLocalDataSource(this.db);

  // Conversations - with transaction support
  Future<void> insertConversation(Conversation conv) async {
    await db.into(db.conversationsTable).insertOnConflictUpdate(ConversationMapper.toCompanion(conv));
  }

  Future<Conversation?> getConversation(String id) async {
    final row = await (db.select(db.conversationsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return ConversationMapper.fromTable(row);
  }

  Future<List<Conversation>> listConversations({bool includeArchived = false, String? projectId}) async {
    final query = db.select(db.conversationsTable)
      ..where((t) {
        final conditions = <Expression<bool>>[];
        if (!includeArchived) conditions.add(t.archived.equals(false));
        if (projectId != null) conditions.add(t.projectId.equals(projectId));
        if (conditions.isEmpty) return const Constant(true);
        return conditions.reduce((a, b) => a & b);
      })
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    final rows = await query.get();
    return rows.map(ConversationMapper.fromTable).toList();
  }

  Future<List<Conversation>> searchConversations(String q) async {
    // FIX: escape like pattern to prevent injection, use custom LIKE
    final escaped = q.replaceAll('%', '\\%').replaceAll('_', '\\_');
    final rows = await (db.select(db.conversationsTable)
          ..where((t) => t.title.like('%\$escaped%'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(ConversationMapper.fromTable).toList();
  }

  Future<void> deleteConversation(String id) async {
    // FIX: Use transaction to ensure atomicity and prevent orphan records
    // With FK CASCADE enabled, deleting conversation auto-deletes messages and attachments
    await db.transaction(() async {
      await (db.delete(db.conversationsTable)..where((t) => t.id.equals(id))).go();
      // Explicit cleanup for safety even with CASCADE
      await (db.delete(db.chatMessagesTable)..where((t) => t.conversationId.equals(id))).go();
    });
  }

  // Messages
  Future<void> insertMessage(ChatMessage msg) async {
    await db.into(db.chatMessagesTable).insertOnConflictUpdate(MessageMapper.toCompanion(msg));
  }

  Future<void> insertMessagesInTransaction(List<ChatMessage> messages) async {
    await db.transaction(() async {
      for (final msg in messages) {
        await db.into(db.chatMessagesTable).insertOnConflictUpdate(MessageMapper.toCompanion(msg));
      }
    });
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

  Future<ChatMessage?> getLastMessage(String conversationId) async {
    final row = await (db.select(db.chatMessagesTable)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return MessageMapper.fromTable(row);
  }

  Future<ChatMessage?> getLastUserMessage(String conversationId) async {
    // For retry/regenerate we need last user message
    final rows = await (db.select(db.chatMessagesTable)
          ..where((t) => t.conversationId.equals(conversationId) & t.role.equals('user'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .get();
    if (rows.isEmpty) return null;
    return MessageMapper.fromTable(rows.first);
  }

  Future<void> deleteMessage(String id) async {
    await (db.delete(db.chatMessagesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateConversationTimestamp(String conversationId) async {
    await (db.update(db.conversationsTable)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTableCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  // For duplicate prevention
  Future<bool> messageExists(String id) async {
    final row = await (db.select(db.chatMessagesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null;
  }
}
