import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('ChatThread + ChatMessage map their rows', () {
    final t = ChatThread.fromJson({
      'thread_id': 't1', 'student_name': 'Sam Rivera', 'company_name': 'Nimbus', 'university_name': 'Springfield',
    });
    expect(t.studentName, 'Sam Rivera');
    final m = ChatMessage.fromJson({
      'id': 'm1', 'thread_id': 't1', 'sender_profile_id': 'u1', 'body': 'Welcome aboard',
      'created_at': '2026-07-01T12:00:00Z',
    });
    expect(m.body, 'Welcome aboard');
    expect(m.threadId, 't1');
  });
}
