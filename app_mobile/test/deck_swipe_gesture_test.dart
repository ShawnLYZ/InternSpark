import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/deck_screen.dart';

/// Exercises the *real drag gesture* (not the fallback buttons): a decisive
/// horizontal drag past the threshold must commit the swipe, and the shadow
/// gate must block an apply-drag until the day-in-the-life clip is opened.
void main() {
  ProviderScope host(FakeDeckRepository fake) => ProviderScope(
        overrides: [
          deckRepositoryProvider.overrideWithValue(fake),
          resumeRepositoryProvider.overrideWithValue(
            FakeResumeRepository(generated: const ResumeJson(name: 'Sam Rivera', headline: 'x')),
          ),
          leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository()),
          reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: DeckScreen())),
      );

  const twoCards = [
    DeckCandidate(
        jobId: 'j1', title: 'Data Analyst Intern', growthText: 'grow', companyName: 'Nimbus',
        matchedSkills: 2, requiredSkills: 3, score: 0.9),
    DeckCandidate(jobId: 'j2', title: 'UX Intern', growthText: 'grow', companyName: 'Brightway', score: 0.4),
  ];

  testWidgets('dragging the card right applies (real swipe)', (tester) async {
    final fake = FakeDeckRepository(deck: twoCards);
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(SwipeCard), const Offset(600, 0));
    await tester.pumpAndSettle();

    expect(fake.swipes, [('j1', 'right')]);
  });

  testWidgets('dragging the card left passes (real swipe)', (tester) async {
    final fake = FakeDeckRepository(deck: twoCards);
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(SwipeCard), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(fake.swipes, [('j1', 'left')]);
  });

  testWidgets('a small drag springs back and does not commit', (tester) async {
    final fake = FakeDeckRepository(deck: twoCards);
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(SwipeCard), const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(fake.swipes, isEmpty);
  });

  testWidgets('apply-drag is blocked while the video gate is closed', (tester) async {
    final fake = FakeDeckRepository(deck: const [
      DeckCandidate(
          jobId: 'j1', title: 'Data Analyst Intern', growthText: 'grow', companyName: 'Nimbus',
          videoPath: 'https://example.com/v.mp4', posterPath: 'https://example.com/p.jpg', score: 0.9),
    ]);
    await tester.pumpWidget(host(fake));
    await tester.pump();

    await tester.drag(find.byType(SwipeCard), const Offset(600, 0));
    await tester.pump(const Duration(milliseconds: 400));

    expect(fake.swipes, isEmpty); // gate blocked the apply; card sprang back
  });
}
