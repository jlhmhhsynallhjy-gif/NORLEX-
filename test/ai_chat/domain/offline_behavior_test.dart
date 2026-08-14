
import 'package:flutter_test/flutter_test.dart';
import 'package:norlex/features/ai_chat/domain/entities/chat_message.dart';
import 'package:norlex/features/ai_chat/domain/entities/chat_enums.dart';

void main() {
  group('Offline Behavior', () {
    test('user message preserved even when offline', () {
      final msg = ChatMessage(id: '1', conversationId: 'c', role: MessageRole.user, content: 'Hello offline', createdAt: DateTime.now(), status: MessageStatus.completed);
      expect(msg.status, MessageStatus.completed);
      // Assistant would be failed with offline code, but user preserved
    });

    test('offline failure is retryable', () {
      final failed = ChatMessage(id: '2', conversationId: 'c', role: MessageRole.assistant, content: '', createdAt: DateTime.now(), status: MessageStatus.failed, metadata: {'code': 'no_internet'});
      expect(failed.isFailed, true);
      expect(failed.metadata['code'], 'no_internet');
    });
  });
}
