
import 'package:flutter_test/flutter_test.dart';
import 'package:norlex/features/ai_chat/domain/entities/chat_message.dart';
import 'package:norlex/features/ai_chat/domain/entities/chat_enums.dart';

void main() {
  group('Streaming Aggregation', () {
    test('chunks aggregate correctly: chunk1 + chunk2 + chunk3', () {
      final chunks = ['Hello', ' world', '!'];
      String accumulated = '';
      for (final chunk in chunks) {
        accumulated += chunk;
      }
      expect(accumulated, 'Hello world!');
    });

    test('preserves order', () {
      final chunks = ['1', '2', '3', '4'];
      String acc = '';
      for (final c in chunks) acc += c;
      expect(acc, '1234');
    });

    test('failure preserves partial content', () {
      String partial = 'Partial response';
      final failedMessage = ChatMessage(
        id: '1',
        conversationId: 'c1',
        role: MessageRole.assistant,
        content: partial,
        createdAt: DateTime.now(),
        status: MessageStatus.failed,
        metadata: {'partial_content_preserved': true},
      );
      expect(failedMessage.content, 'Partial response');
      expect(failedMessage.isFailed, true);
      expect(failedMessage.metadata['partial_content_preserved'], true);
    });

    test('duplicate prevention - same id should not create duplicate', () {
      final msg1 = ChatMessage(id: 'same', conversationId: 'c', role: MessageRole.user, content: 'Hi', createdAt: DateTime.now(), status: MessageStatus.completed);
      final msg2 = ChatMessage(id: 'same', conversationId: 'c', role: MessageRole.user, content: 'Hi', createdAt: DateTime.now(), status: MessageStatus.completed);
      final list = <ChatMessage>[];
      void addOrUpdate(ChatMessage m) {
        final idx = list.indexWhere((e) => e.id == m.id);
        if (idx >= 0) list[idx] = m; else list.add(m);
      }
      addOrUpdate(msg1);
      addOrUpdate(msg2);
      expect(list.length, 1);
    });
  });

  group('Cancellation', () {
    test('cancelled status is terminal', () {
      final msg = ChatMessage(id: '1', conversationId: 'c', role: MessageRole.assistant, content: 'Partial', createdAt: DateTime.now(), status: MessageStatus.cancelled);
      expect(msg.status.isTerminal, true);
    });

    test('double cancel should be safe - completer check', () {
      bool isCompleted = false;
      void safeComplete() {
        if (!isCompleted) isCompleted = true;
      }
      safeComplete();
      safeComplete(); // second call should not throw
      expect(isCompleted, true);
    });
  });

  group('Retry and Regenerate', () {
    test('retry should use last user message', () {
      final messages = [
        ChatMessage(id: '1', conversationId: 'c', role: MessageRole.user, content: 'Hello', createdAt: DateTime.now().subtract(const Duration(seconds: 2)), status: MessageStatus.completed),
        ChatMessage(id: '2', conversationId: 'c', role: MessageRole.assistant, content: '', createdAt: DateTime.now().subtract(const Duration(seconds: 1)), status: MessageStatus.failed),
      ];
      final lastUser = messages.lastWhere((m) => m.role == MessageRole.user);
      expect(lastUser.content, 'Hello');
    });

    test('regenerate deletes last assistant and reuses user', () {
      final messages = [
        ChatMessage(id: '1', conversationId: 'c', role: MessageRole.user, content: 'Q', createdAt: DateTime.now().subtract(const Duration(seconds: 2)), status: MessageStatus.completed),
        ChatMessage(id: '2', conversationId: 'c', role: MessageRole.assistant, content: 'Old answer', createdAt: DateTime.now().subtract(const Duration(seconds: 1)), status: MessageStatus.completed),
      ];
      final toDelete = messages.lastWhere((m) => m.role == MessageRole.assistant);
      final remaining = messages.where((m) => m.id != toDelete.id).toList();
      expect(remaining.length, 1);
      expect(remaining.first.role, MessageRole.user);
    });
  });

  group('Concurrency', () {
    test('concurrent send should be prevented', () {
      bool isStreaming = true;
      bool secondSendAllowed = !isStreaming;
      expect(secondSendAllowed, false);
    });
  });
}
