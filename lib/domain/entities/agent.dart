enum AgentType { chat, coder, researcher, designer, general }

enum AgentRunStatus { queued, running, completed, failed, cancelled, waitingApproval }

class Agent {
  final String id;
  final String name;
  final AgentType type;
  final String? description;
  final List<String> toolIds;
  final Map<String, dynamic> config;
  final DateTime createdAt;

  const Agent({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.toolIds = const [],
    this.config = const {},
    required this.createdAt,
  });

}

class AgentRun {
  final String id;
  final String agentId;
  final String taskId;
  final AgentRunStatus status;
  final List<ToolCall> toolCalls;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const AgentRun({
    required this.id,
    required this.agentId,
    required this.taskId,
    required this.status,
    this.toolCalls = const [],
    required this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

}

class ToolCall {
  final String id;
  final String toolName;
  final Map<String, dynamic> arguments;
  final ToolResult? result;
  final DateTime createdAt;

  const ToolCall({
    required this.id,
    required this.toolName,
    required this.arguments,
    this.result,
    required this.createdAt,
  });

}

class ToolResult {
  final String toolCallId;
  final bool success;
  final dynamic data;
  final String? error;
  final DateTime createdAt;

  const ToolResult({
    required this.toolCallId,
    required this.success,
    this.data,
    this.error,
    required this.createdAt,
  });

}

class ApprovalRequest {
  final String id;
  final String runId;
  final String toolCallId;
  final String reason;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final bool? approved;

  const ApprovalRequest({
    required this.id,
    required this.runId,
    required this.toolCallId,
    required this.reason,
    this.details = const {},
    required this.createdAt,
    this.approved,
  });

}
