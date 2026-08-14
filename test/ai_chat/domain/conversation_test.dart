import 'package:flutter_test/flutter_test.dart';
import 'package:norlex/features/ai_chat/domain/entities/conversation.dart';

void main() {
  group('Conversation', () {
    test('create conversation', () {
      final now = DateTime.now();
      final conv = Conversation(
        id: '1',
        userId: 'user1',
        title: 'Test Chat',
        createdAt: now,
        updatedAt: now,
      );
      expect(conv.id, '1');
      expect(conv.archived, false);
    });

    test('copyWith updates title', () {
      final now = DateTime.now();
      final conv = Conversation(id: '1', userId: 'u', title: 'Old', createdAt: now, updatedAt: now);
      final updated = conv.copyWith(title: 'New');
      expect(updated.title, 'New');
      expect(updated.id, '1');
    });

    test('archived flag', () {
      final now = DateTime.now();
      final conv = Conversation(id: '1', userId: 'u', title: 'T', createdAt: now, updatedAt: now, archived: true);
      expect(conv.archived, true);
    });
  });
}
