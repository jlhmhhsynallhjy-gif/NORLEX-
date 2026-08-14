import 'chat_enums.dart';

class ChatAttachment {
  final String id;
  final String fileId;
  final AttachmentType type;
  final String name;
  final String mimeType;
  final int size;
  final Map<String, dynamic> metadata;

  const ChatAttachment({
    required this.id,
    required this.fileId,
    required this.type,
    required this.name,
    required this.mimeType,
    required this.size,
    this.metadata = const {},
  });

  ChatAttachment copyWith({
    String? id,
    String? fileId,
    AttachmentType? type,
    String? name,
    String? mimeType,
    int? size,
    Map<String, dynamic>? metadata,
  }) {
    return ChatAttachment(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      type: type ?? this.type,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      metadata: metadata ?? this.metadata,
    );
  }
}
