import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/applicants_screen.dart';

void main() {
  testWidgets('pre-match applicant is anonymous, shows fit chips, and can be matched', (tester) async {
    final fake = FakeApplicantsRepository(rows: const [
      ApplicantRow(
        applicationId: 'a1', status: ApplicationStatus.applied, matched: false,
        requiredSkills: ['SQL', 'Python', 'Figma'], studentSkills: ['SQL', 'Python'],
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        applicantsRepositoryProvider.overrideWithValue(fake),
        selectedJobIdProvider.overrideWithBuild((ref, _) => 'job-1'),
      ],
      child: const MaterialApp(home: Scaffold(body: ApplicantsScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Anonymous candidate'), findsOneWidget);
    expect(find.text('67% fit'), findsOneWidget); // 2 of 3 required
    expect(find.widgetWithText(Chip, 'SQL'), findsOneWidget);
    expect(find.text('Skills verified by InternSpark'), findsOneWidget);

    await tester.tap(find.byKey(const Key('match')));
    await tester.pumpAndSettle();
    expect(fake.swipes, [('a1', 'right')]);
  });
}
