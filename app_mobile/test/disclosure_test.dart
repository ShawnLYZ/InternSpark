import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/matches_screen.dart';

void main() {
  testWidgets('accepting an offer shows the coordination disclosure', (tester) async {
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
    expect(find.byKey(const Key('disclosure')), findsOneWidget);
    expect(find.textContaining('can now coordinate'), findsOneWidget);
  });
}
