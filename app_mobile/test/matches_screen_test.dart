import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/matches_screen.dart';

void main() {
  testWidgets('a matched app shows a live countdown', (tester) async {
    final fake = FakeApplicationRepository(apps: [
      Application(
        id: 'a1', jobId: 'j1', jobTitle: 'Data Analyst Intern', companyName: 'Nimbus',
        status: ApplicationStatus.matched, matchedAt: DateTime.now().toUtc(),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [applicationRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: Scaffold(body: MatchesScreen())),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(SparkCountdown), findsOneWidget);
  });

  testWidgets('an offer can be accepted (→ placed)', (tester) async {
    final fake = FakeApplicationRepository(apps: const [
      Application(id: 'a1', jobId: 'j1', jobTitle: 'UX Intern', companyName: 'Brightway',
          status: ApplicationStatus.offer),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [applicationRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: Scaffold(body: MatchesScreen())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accept')));
    await tester.pumpAndSettle();
    expect(fake.accepted, ['a1']);
  });
}
