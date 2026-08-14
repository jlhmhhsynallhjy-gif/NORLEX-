enum ToolCategory { file, code, search, api, system, ai }

class NorlexTool {
  final String id;
  final String name;
  final String description;
  final ToolCategory category;
  final Map<String, dynamic> inputSchema;
  final bool requiresApproval;

  const NorlexTool({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.inputSchema,
    this.requiresApproval = false,
  });

}
