import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/review_compose_screen.dart';

void main() {
  testWidgets('no report → nudge appears; "Post anyway" posts (never blocks)', (tester) async {
    final fake = FakeReviewRepository(reportRefs: const []); // no report filed about me
    await tester.pumpWidget(ProviderScope(
      overrides: [reviewRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: ReviewComposeScreen(companyId: 'c1', companyName: 'Nimbus')),
    ));

    await tester.enterText(find.byType(TextField), 'Great mentorship');
    await tester.tap(find.byKey(const Key('post-review')));
    await tester.pumpAndSettle();

    // The nudge is shown but does not block.
    expect(find.text('Post anyway?'), findsOneWidget);
    expect(fake.posted, isNull);

    await tester.tap(find.byKey(const Key('post-anyway')));
    await tester.pumpAndSettle();
    expect(fake.posted?['companyId'], 'c1');
  });

  testWidgets('report filed → no nudge, posts directly', (tester) async {
    final fake = FakeReviewRepository(
      reportRefs: const [ReportRef(studentId: '', companyId: 'c1')], // matches (uid is '' in tests)
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [reviewRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: ReviewComposeScreen(companyId: 'c1', companyName: 'Nimbus')),
    ));

    await tester.enterText(find.byType(TextField), 'Great mentorship');
    await tester.tap(find.byKey(const Key('post-review')));
    await tester.pumpAndSettle();

    expect(find.text('Post anyway?'), findsNothing);
    expect(fake.posted?['companyId'], 'c1');
  });
}
