enum MessageRole { user, assistant, system, tool }

extension MessageRoleX on MessageRole {
  String get name => toString().split('.').last;
  static MessageRole fromString(String s) {
    return MessageRole.values.firstWhere((e) => e.name == s, orElse: () => MessageRole.user);
  }
}

enum MessageStatus { sending, streaming, completed, failed, cancelled }

extension MessageStatusX on MessageStatus {
  String get name => toString().split('.').last;
  static MessageStatus fromString(String s) {
    return MessageStatus.values.firstWhere((e) => e.name == s, orElse: () => MessageStatus.completed);
  }
  bool get isTerminal => this == MessageStatus.completed || this == MessageStatus.failed || this == MessageStatus.cancelled;
}

enum AttachmentType { image, document, audio, other }

extension AttachmentTypeX on AttachmentType {
  String get name => toString().split('.').last;
  static AttachmentType fromString(String s) {
    return AttachmentType.values.firstWhere((e) => e.name == s, orElse: () => AttachmentType.other);
  }
  static AttachmentType fromMime(String mime) {
    if (mime.startsWith('image/')) return AttachmentType.image;
    if (mime.startsWith('audio/')) return AttachmentType.audio;
    if (mime == 'application/pdf' || mime.contains('document') || mime.contains('text')) return AttachmentType.document;
    return AttachmentType.other;
  }
}
