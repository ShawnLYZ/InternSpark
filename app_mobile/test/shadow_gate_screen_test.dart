import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/deck_screen.dart';

void main() {
  testWidgets('a video job gates apply until watched/expanded', (tester) async {
    final fake = FakeDeckRepository(deck: const [
      DeckCandidate(
          jobId: 'j1',
          title: 'Data Analyst Intern',
          growthText: 'grow',
          companyName: 'Nimbus',
          videoPath: 'https://example.com/v.mp4',
          posterPath: 'https://example.com/p.jpg',
          score: 0.9),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        deckRepositoryProvider.overrideWithValue(fake),
        leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository()),
        reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
      ],
      child: const MaterialApp(home: Scaffold(body: DeckScreen())),
    ));
    await tester.pump(); // single frame; do not settle on network images

    // Apply is gated.
    final apply = tester.widget<IconButton>(find.byKey(const Key('apply')));
    expect(apply.onPressed, isNull);
    expect(find.text('Watch the day-in-the-life to apply'), findsOneWidget);

    // Tap-to-expand opens the gate (never hard-blocks).
    await tester.tap(find.byKey(const Key('watch')));
    await tester.pump();
    final apply2 = tester.widget<IconButton>(find.byKey(const Key('apply')));
    expect(apply2.onPressed, isNotNull);
  });

  testWidgets('a no-video job is immediately swipeable', (tester) async {
    final fake = FakeDeckRepository(deck: const [
      DeckCandidate(
          jobId: 'j2',
          title: 'UX Intern',
          growthText: 'grow',
          companyName: 'Brightway',
          score: 0.5),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        deckRepositoryProvider.overrideWithValue(fake),
        leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository()),
        reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
      ],
      child: const MaterialApp(home: Scaffold(body: DeckScreen())),
    ));
    await tester.pump();
    expect(tester.widget<IconButton>(find.byKey(const Key('apply'))).onPressed, isNotNull);
  });
}
