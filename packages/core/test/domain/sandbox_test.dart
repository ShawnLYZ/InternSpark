import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  final matchedAt = DateTime.utc(2026, 7, 1, 12);
  final deadline = sandboxDeadline(matchedAt);

  test('sandboxDeadline is matched_at + 48h', () {
    expect(deadline, DateTime.utc(2026, 7, 3, 12));
  });

  group('sandboxTransition', () {
    test('draft + submit before deadline → submitted', () {
      expect(
        sandboxTransition(SandboxStatus.draft, SandboxEvent.submit,
            now: DateTime.utc(2026, 7, 2), deadline: deadline),
        SandboxStatus.submitted,
      );
    });
    test('draft + submit after deadline → not_submitted', () {
      expect(
        sandboxTransition(SandboxStatus.draft, SandboxEvent.submit,
            now: DateTime.utc(2026, 7, 4), deadline: deadline),
        SandboxStatus.notSubmitted,
      );
    });
    test('draft + lapse after deadline → not_submitted (no penalty)', () {
      expect(
        sandboxTransition(SandboxStatus.draft, SandboxEvent.lapse,
            now: DateTime.utc(2026, 7, 4), deadline: deadline),
        SandboxStatus.notSubmitted,
      );
    });
    test('draft + lapse before deadline → still draft', () {
      expect(
        sandboxTransition(SandboxStatus.draft, SandboxEvent.lapse,
            now: DateTime.utc(2026, 7, 2), deadline: deadline),
        SandboxStatus.draft,
      );
    });
    test('submitted + review → reviewed', () {
      expect(
        sandboxTransition(SandboxStatus.submitted, SandboxEvent.review, now: DateTime.utc(2026, 7, 5), deadline: deadline),
        SandboxStatus.reviewed,
      );
    });
    test('terminal states are unchanged', () {
      for (final s in [SandboxStatus.notSubmitted, SandboxStatus.reviewed]) {
        expect(sandboxTransition(s, SandboxEvent.submit, now: matchedAt, deadline: deadline), s);
      }
    });
  });
}
