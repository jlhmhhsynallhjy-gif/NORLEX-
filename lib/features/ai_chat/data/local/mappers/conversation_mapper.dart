import 'dart:convert';
import '../tables/conversations_table.dart';
import '../../domain/entities/conversation.dart';
import 'package:drift/drift.dart';

class ConversationMapper {
  static Conversation fromTable(ConversationsTableData data) {
    return Conversation(
      id: data.id,
      userId: data.userId,
      projectId: data.projectId,
      title: data.title,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      archived: data.archived,
      metadata: _decodeMeta(data.metadata),
    );
  }

  static ConversationsTableCompanion toCompanion(Conversation conv) {
    return ConversationsTableCompanion(
      id: Value(conv.id),
      userId: Value(conv.userId),
      projectId: Value(conv.projectId),
      title: Value(conv.title),
      createdAt: Value(conv.createdAt),
      updatedAt: Value(conv.updatedAt),
      archived: Value(conv.archived),
      metadata: Value(jsonEncode(conv.metadata)),
    );
  }

  static Map<String, dynamic> _decodeMeta(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
