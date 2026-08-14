
import 'package:flutter/material.dart';

class ChatComposer extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback onStop;
  final VoidCallback? onAttach;
  final VoidCallback? onVoice;
  final bool isStreaming;
  const ChatComposer({super.key, required this.onSend, required this.onStop, this.onAttach, this.onVoice, required this.isStreaming});
  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  @override
  void dispose() { _controller.dispose(); _focus.dispose(); super.dispose(); }
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _focus.requestFocus();
  }
  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          IconButton(icon: const Icon(Icons.attach_file), onPressed: widget.onAttach, tooltip: 'Attach'),
          Expanded(child: TextField(controller: _controller, focusNode: _focus, minLines: 1, maxLines: 5, decoration: InputDecoration(hintText: isRtl ? 'رسالة إلى نورلكس...' : 'Message NORLEX...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)), onSubmitted: (_) => _handleSend(), textInputAction: TextInputAction.send)),
          const SizedBox(width: 8),
          if (widget.isStreaming) IconButton.filled(onPressed: widget.onStop, icon: const Icon(Icons.stop)) else IconButton.filled(onPressed: _handleSend, icon: const Icon(Icons.send)),
          if (!widget.isStreaming) IconButton(icon: const Icon(Icons.mic), onPressed: widget.onVoice),
        ],
      ),
    );
  }
}
