import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  final matchedAt = DateTime.utc(2026, 7, 1, 12);

  test('ghostDeadline is matched_at + 7 days', () {
    expect(ghostDeadline(matchedAt), DateTime.utc(2026, 7, 8, 12));
  });

  test('countdownRemaining clamps to zero once past the deadline', () {
    final deadline = ghostDeadline(matchedAt);
    expect(countdownRemaining(deadline, DateTime.utc(2026, 7, 2, 12)), const Duration(days: 6));
    expect(countdownRemaining(deadline, DateTime.utc(2026, 7, 9, 12)), Duration.zero);
  });

  test('formatCountdown renders days+hours, and Expired at zero', () {
    expect(formatCountdown(const Duration(days: 6, hours: 23, minutes: 5)), '6d 23h');
    expect(formatCountdown(const Duration(hours: 5)), '0d 5h');
    expect(formatCountdown(Duration.zero), 'Expired');
  });
}
