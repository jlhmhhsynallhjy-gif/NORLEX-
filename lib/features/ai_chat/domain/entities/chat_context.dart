import 'conversation.dart';
import 'chat_message.dart';

class ChatContext {
  final Conversation conversation;
  final List<ChatMessage> relevantMessages;
  final String? projectContext;
  final Map<String, dynamic>? userMemory;
  final List<String> attachmentIds;

  const ChatContext({
    required this.conversation,
    required this.relevantMessages,
    this.projectContext,
    this.userMemory,
    this.attachmentIds = const [],
  });

  Map<String, dynamic> toAiPayload() {
    return {
      'conversation_id': conversation.id,
      'project_id': conversation.projectId,
      'messages': relevantMessages.map((m) => {
        'role': m.role.name,
        'content': m.content,
      }).toList(),
      'project_context': projectContext,
      'has_attachments': attachmentIds.isNotEmpty,
    };
  }
}
