import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/employer_shell.dart';

void main() {
  testWidgets('employer header shows the company ghost badge', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        employerRepositoryProvider.overrideWithValue(
          FakeEmployerRepository(company: const Company(id: 'c1', name: 'Nimbus Analytics'))),
        jobRepositoryProvider.overrideWithValue(FakeJobRepository(jobs: const [])),
        leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository(
          mine: const CompanyGhostStats(companyId: 'c1', companyName: 'Nimbus Analytics',
              totalMatches: 7, ghostRate: 0.15))),
      ],
      child: const MaterialApp(home: EmployerShell()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('15% ghosted'), findsOneWidget);
  });
}
