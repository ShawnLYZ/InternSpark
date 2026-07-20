import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  final now = DateTime.utc(2026, 8, 1, 12);
  MatchRecord m(int daysAgo, {int? respondedDaysAfter}) => MatchRecord(
        matchedAt: now.subtract(Duration(days: daysAgo)),
        firstResponseAt:
            respondedDaysAfter == null ? null : now.subtract(Duration(days: daysAgo - respondedDaysAfter)),
      );

  group('isGhosted', () {
    test('matched 8 days ago with no response → ghosted', () {
      expect(isGhosted(m(8), now), isTrue);
    });
    test('matched 3 days ago with no response yet → not ghosted (still in window)', () {
      expect(isGhosted(m(3), now), isFalse);
    });
    test('responded within 7 days → not ghosted', () {
      expect(isGhosted(m(8, respondedDaysAfter: 2), now), isFalse);
    });
    test('responded after the 7-day window → ghosted (no in-window next-step)', () {
      expect(isGhosted(m(10, respondedDaysAfter: 9), now), isTrue);
    });
  });

  group('ghostRate (rolling 90 days)', () {
    test('ghosted ÷ total over the window', () {
      final matches = [m(8), m(8, respondedDaysAfter: 1), m(8), m(3)]; // 2 ghosted of 4
      expect(ghostRate(matches, now), closeTo(0.5, 1e-9));
    });
    test('matches older than 90 days are excluded', () {
      expect(ghostRate([m(120), m(8)], now), 1.0); // only the 8-day match counts; it is ghosted
    });
  });

  group('avgResponseTime', () {
    test('mean over resolved; ghosted counts as the full 7 days', () {
      // one responded in 2 days, one ghosted (=7 days); pending (3d) excluded.
      final avg = avgResponseTime([m(8, respondedDaysAfter: 2), m(8), m(3)], now);
      expect(avg, const Duration(days: 4, hours: 12)); // mean(2d, 7d) = 4.5 days
    });
  });

  group('gates + ranking', () {
    test('minSampleGate requires 5 matches', () {
      expect(minSampleGate(4), isFalse);
      expect(minSampleGate(5), isTrue);
    });
    test('rankLeaderboard puts enough-data companies first by ascending ghost rate', () {
      final ranked = rankLeaderboard([
        const CompanyGhostStats(companyId: 'a', companyName: 'A', totalMatches: 6, ghostRate: 0.4),
        const CompanyGhostStats(companyId: 'b', companyName: 'B', totalMatches: 2, ghostRate: 0.0),
        const CompanyGhostStats(companyId: 'c', companyName: 'C', totalMatches: 8, ghostRate: 0.1),
      ]);
      expect(ranked.map((c) => c.companyId).toList(), ['c', 'a', 'b']); // c,a ranked; b gated → last
    });
  });
}
