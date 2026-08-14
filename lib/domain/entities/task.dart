enum TaskStatus { queued, running, waiting, completed, failed, cancelled, needsApproval }

enum TaskPriority { low, medium, high, critical }

class NorlexTask {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final Map<String, dynamic> payload;
  final String? assignedAgentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NorlexTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.status = TaskStatus.queued,
    this.priority = TaskPriority.medium,
    this.payload = const {},
    this.assignedAgentId,
    required this.createdAt,
    required this.updatedAt,
  });

}
