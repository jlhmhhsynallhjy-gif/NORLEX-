enum ProjectType { general, chat, code, app, research, content }

enum ProjectStatus { active, archived, deleted }

class Project {
  final String id;
  final String name;
  final String? description;
  final ProjectType type;
  final ProjectStatus status;
  final Map<String, dynamic> aiContext;
  final List<String> fileIds;
  final List<String> conversationIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.type = ProjectType.general,
    this.status = ProjectStatus.active,
    this.aiContext = const {},
    this.fileIds = const [],
    this.conversationIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

}
