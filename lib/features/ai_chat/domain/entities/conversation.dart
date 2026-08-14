class Conversation {
  final String id;
  final String userId;
  final String? projectId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final Map<String, dynamic> metadata;

  const Conversation({
    required this.id,
    required this.userId,
    this.projectId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
    this.metadata = const {},
  });

  Conversation copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      metadata: metadata ?? this.metadata,
    );
  }
}
