import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/review_compose_screen.dart';

void main() {
  testWidgets('profanity blocks the post; clean text posts', (tester) async {
    final fake = FakeReviewRepository(reportRefs: const [ReportRef(studentId: '', companyId: 'c1')]);
    await tester.pumpWidget(ProviderScope(
      overrides: [reviewRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: ReviewComposeScreen(companyId: 'c1', companyName: 'Nimbus')),
    ));

    await tester.enterText(find.byType(TextField), 'This was a damn waste');
    await tester.tap(find.byKey(const Key('post-review')));
    await tester.pumpAndSettle();
    expect(find.textContaining('inappropriate language'), findsOneWidget);
    expect(fake.posted, isNull);

    await tester.enterText(find.byType(TextField), 'Great mentorship and fair workload');
    await tester.tap(find.byKey(const Key('post-review')));
    await tester.pumpAndSettle();
    expect(fake.posted?['companyId'], 'c1');
  });
}
