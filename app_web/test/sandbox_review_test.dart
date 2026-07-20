import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/sandbox_review_screen.dart';

void main() {
  testWidgets('employer runs AI assess then records a verdict', (tester) async {
    final fake = FakeSandboxRepository(jobSubs: const [
      SandboxSubmission(
          id: 'sb1',
          status: SandboxStatus.submitted,
          studentName: 'Sam Rivera',
          text: 'Three insights: ...'),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [sandboxRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(
          home: SandboxReviewScreen(jobId: 'j1', jobTitle: 'Data Analyst Intern')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sam Rivera · submitted'), findsOneWidget);
    await tester.tap(find.byKey(const Key('assess')));
    await tester.pumpAndSettle();
    expect(find.textContaining('AI assessment'), findsOneWidget);

    await tester.tap(find.byKey(const Key('strong')));
    await tester.pumpAndSettle();
    expect(fake.verdict?['verdict'], 'strong');
  });
}
