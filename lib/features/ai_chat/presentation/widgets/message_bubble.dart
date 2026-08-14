import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_enums.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onRegenerate,
    this.onDelete,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? (isRtl ? Alignment.centerLeft : Alignment.centerRight) : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: message.isFailed ? Border.all(color: theme.colorScheme.error) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachments.isNotEmpty)
              Wrap(
                spacing: 8,
                children: message.attachments.map((a) => Chip(label: Text(a.name), avatar: Icon(_iconForType(a.type)))).toList(),
              ),
            SelectableText(
              message.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isUser ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(color: isUser ? Colors.white70 : Colors.grey),
                ),
                if (message.isStreaming) ...[
                  const SizedBox(width: 8),
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: isUser ? Colors.white : theme.colorScheme.primary)),
                ],
                if (message.isFailed) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
                  const SizedBox(width: 4),
                  Text(message.metadata['code']?.toString() ?? 'failed', style: TextStyle(color: theme.colorScheme.error, fontSize: 11)),
                ],
              ],
            ),
            if (!isUser || message.isFailed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isFailed)
                    TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 16), label: const Text('Retry')),
                  IconButton(icon: const Icon(Icons.copy, size: 16), onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    if (onCopy != null) onCopy!();
                  }),
                  if (!isUser) IconButton(icon: const Icon(Icons.refresh, size: 16), onPressed: onRegenerate, tooltip: 'Regenerate'),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 16), onPressed: onDelete),
                ],
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(AttachmentType type) {
    switch (type) {
      case AttachmentType.image: return Icons.image;
      case AttachmentType.document: return Icons.description;
      case AttachmentType.audio: return Icons.audiotrack;
      default: return Icons.attach_file;
    }
  }

  String _formatTime(DateTime dt) {
    return '\${dt.hour.toString().padLeft(2, '0')}:\${dt.minute.toString().padLeft(2, '0')}';
  }
}
