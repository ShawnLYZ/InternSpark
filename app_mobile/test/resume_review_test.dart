import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/resume_review_screen.dart';

void main() {
  testWidgets('edits the headline and attaches the resume', (tester) async {
    final fake = FakeResumeRepository(
      generated: const ResumeJson(name: 'Sam Rivera', headline: 'Aspiring analyst', summary: 'Builds dashboards.'),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [resumeRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: ResumeReviewScreen(applicationId: 'a1', jobId: 'j1')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sam Rivera'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Headline').first, 'Data Analyst Intern candidate');
    await tester.tap(find.byKey(const Key('attach')));
    await tester.pumpAndSettle();

    expect(fake.attachedTo, 'a1');
    expect(fake.attached?.headline, 'Data Analyst Intern candidate');
  });
}
