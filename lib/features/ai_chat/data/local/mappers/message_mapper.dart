import 'dart:convert';
import '../tables/chat_messages_table.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_enums.dart';
import 'package:drift/drift.dart';

class MessageMapper {
  static ChatMessage fromTable(ChatMessagesTableData data) {
    return ChatMessage(
      id: data.id,
      conversationId: data.conversationId,
      role: MessageRoleX.fromString(data.role),
      content: data.content,
      createdAt: data.createdAt,
      status: MessageStatusX.fromString(data.status),
      modelId: data.modelId,
      providerId: data.providerId,
      metadata: _decodeMeta(data.metadata),
    );
  }

  static ChatMessagesTableCompanion toCompanion(ChatMessage msg) {
    return ChatMessagesTableCompanion(
      id: Value(msg.id),
      conversationId: Value(msg.conversationId),
      role: Value(msg.role.name),
      content: Value(msg.content),
      createdAt: Value(msg.createdAt),
      status: Value(msg.status.name),
      modelId: Value(msg.modelId),
      providerId: Value(msg.providerId),
      metadata: Value(jsonEncode(msg.metadata)),
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
