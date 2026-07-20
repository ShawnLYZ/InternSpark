import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/deck_screen.dart';

void main() {
  testWidgets('renders the top card and applies on swipe-right', (tester) async {
    final fake = FakeDeckRepository(deck: const [
      DeckCandidate(jobId: 'j1', title: 'Data Analyst Intern', growthText: 'grow', companyName: 'Nimbus',
          matchedSkills: 2, requiredSkills: 3, score: 0.9),
      DeckCandidate(jobId: 'j2', title: 'UX Intern', growthText: 'grow', companyName: 'Brightway', score: 0.4),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        deckRepositoryProvider.overrideWithValue(fake),
        resumeRepositoryProvider.overrideWithValue(
          FakeResumeRepository(generated: const ResumeJson(name: 'Sam Rivera', headline: 'x')),
        ),
        leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository()),
        reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
      ],
      child: const MaterialApp(home: Scaffold(body: DeckScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Data Analyst Intern'), findsOneWidget);
    await tester.tap(find.byKey(const Key('apply')));
    await tester.pumpAndSettle();
    expect(fake.swipes, [('j1', 'right')]);
  });

  testWidgets('empty deck shows broaden + undo', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        deckRepositoryProvider.overrideWithValue(FakeDeckRepository(deck: const [])),
        leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository()),
        reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
      ],
      child: const MaterialApp(home: Scaffold(body: DeckScreen())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Broaden filters'), findsOneWidget);
    expect(find.text('Undo last swipe'), findsOneWidget);
  });
}
