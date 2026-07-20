import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/leaderboard_screen.dart';

void main() {
  testWidgets('ranks enough-data companies and gates small ones', (tester) async {
    final fake = FakeLeaderboardRepository(stats: const [
      CompanyGhostStats(companyId: 'a', companyName: 'GhostCorp', totalMatches: 6, ghostRate: 0.5),
      CompanyGhostStats(companyId: 'b', companyName: 'Responsive Inc', totalMatches: 8, ghostRate: 0.05),
      CompanyGhostStats(companyId: 'c', companyName: 'Tiny LLC', totalMatches: 2, ghostRate: 0.0),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [leaderboardRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: Scaffold(body: LeaderboardScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Responsive Inc'), findsOneWidget);
    expect(find.text('5% ghosted'), findsOneWidget);   // 0.05 → 5%
    expect(find.text('Not enough data'), findsOneWidget); // Tiny LLC gated

    // Ranking: Responsive Inc (lowest ghost rate) appears above GhostCorp.
    final responsiveY = tester.getTopLeft(find.text('Responsive Inc')).dy;
    final ghostY = tester.getTopLeft(find.text('GhostCorp')).dy;
    expect(responsiveY, lessThan(ghostY));
  });
}
