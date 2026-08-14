import 'chat_enums.dart';
import 'attachment.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final String? modelId;
  final String? providerId;
  final List<ChatAttachment> attachments;
  final Map<String, dynamic> metadata;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
    this.modelId,
    this.providerId,
    this.attachments = const [],
    this.metadata = const {},
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isStreaming => status == MessageStatus.streaming;
  bool get isFailed => status == MessageStatus.failed;
  bool get isCompleted => status == MessageStatus.completed;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
    String? modelId,
    String? providerId,
    List<ChatAttachment>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      modelId: modelId ?? this.modelId,
      providerId: providerId ?? this.providerId,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }
}
