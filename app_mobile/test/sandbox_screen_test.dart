import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/sandbox_screen.dart';

void main() {
  testWidgets('student saves a draft then submits', (tester) async {
    final fake = FakeSandboxRepository();
    final sub = SandboxSubmission(
      id: 'sb1', status: SandboxStatus.draft, jobTitle: 'Data Analyst Intern',
      prompt: 'Summarize 3 insights from this CSV.', deadlineAt: DateTime.now().toUtc().add(const Duration(hours: 40)),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [sandboxRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(home: SandboxScreen(submission: sub)),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Insight 1, 2, 3');
    await tester.tap(find.byKey(const Key('save-draft')));
    await tester.pumpAndSettle();
    expect(fake.draftSaved, 'Insight 1, 2, 3');

    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    expect(fake.submitted, 'sb1');
  });
}
