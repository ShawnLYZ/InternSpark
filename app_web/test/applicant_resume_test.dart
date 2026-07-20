import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/applicants_screen.dart';

void main() {
  testWidgets('pre-match resume is shown as "Candidate" (name redacted)', (tester) async {
    final fake = FakeApplicantsRepository(rows: const [
      ApplicantRow(applicationId: 'a1', status: ApplicationStatus.applied, matched: false,
          requiredSkills: ['SQL'], studentSkills: ['SQL']),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        applicantsRepositoryProvider.overrideWithValue(fake),
        selectedJobIdProvider.overrideWithBuild((ref, _) => 'job-1'),
        resumeRepositoryProvider.overrideWithValue(FakeResumeRepository(
          generated: const ResumeJson(name: 'Sam Rivera', headline: 'Aspiring analyst'),
        )),
      ],
      child: const MaterialApp(home: Scaffold(body: ApplicantsScreen())),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('view-resume')));
    await tester.pumpAndSettle();
    expect(find.text('Candidate'), findsOneWidget);
    expect(find.text('Sam Rivera'), findsNothing);
  });
}
