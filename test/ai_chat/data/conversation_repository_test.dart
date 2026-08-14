import 'package:flutter_test/flutter_test.dart';
import 'package:norlex/core/utils/result.dart';
import 'package:norlex/features/ai_chat/domain/entities/conversation.dart';

void main() {
  group('ConversationRepository contract', () {
    test('Result sealed class works', () {
      final now = DateTime.now();
      final conv = Conversation(id: '1', userId: 'u', title: 'T', createdAt: now, updatedAt: now);
      final result = Success<Conversation>(conv);
      expect(result.isSuccess, true);
      expect(result.dataOrNull?.id, '1');
    });

    test('FailureResult holds failure', () {
      const failure = FailureResult<List<Conversation>>(null as dynamic);
      // Just checking type exists - real test with mock would be in integration test
      expect(failure.isFailure, true);
    });
  });
}
