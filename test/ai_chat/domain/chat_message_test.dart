import 'package:flutter_test/flutter_test.dart';
import 'package:norlex/features/ai_chat/domain/entities/chat_message.dart';
import 'package:norlex/features/ai_chat/domain/entities/chat_enums.dart';

void main() {
  group('ChatMessage', () {
    test('message statuses', () {
      final msg = ChatMessage(
        id: '1',
        conversationId: 'c1',
        role: MessageRole.user,
        content: 'Hello',
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
      );
      expect(msg.isUser, true);
      expect(msg.isStreaming, false);
      expect(msg.status.isTerminal, false);
    });

    test('failed state preserves content', () {
      final msg = ChatMessage(
        id: '1',
        conversationId: 'c1',
        role: MessageRole.assistant,
        content: 'Partial',
        createdAt: DateTime.now(),
        status: MessageStatus.failed,
        metadata: {'error': 'timeout'},
      );
      expect(msg.isFailed, true);
      expect(msg.content, 'Partial');
      expect(msg.metadata['error'], 'timeout');
    });

    test('ordering by createdAt', () {
      final now = DateTime.now();
      final m1 = ChatMessage(id: '1', conversationId: 'c', role: MessageRole.user, content: 'A', createdAt: now, status: MessageStatus.completed);
      final m2 = ChatMessage(id: '2', conversationId: 'c', role: MessageRole.assistant, content: 'B', createdAt: now.add(const Duration(seconds: 1)), status: MessageStatus.completed);
      final list = [m2, m1]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(list.first.id, '1');
    });

    test('cancellation state', () {
      final msg = ChatMessage(
        id: '1',
        conversationId: 'c1',
        role: MessageRole.assistant,
        content: 'Partial response',
        createdAt: DateTime.now(),
        status: MessageStatus.cancelled,
      );
      expect(msg.status, MessageStatus.cancelled);
      expect(msg.status.isTerminal, true);
    });
  });
}
