import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/profile_screen.dart';

void main() {
  Widget host(FakeAuthRepository auth, {List<VerifiedSkill> skills = const []}) => ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          studentRepositoryProvider.overrideWithValue(FakeStudentRepository(
            studentProfile: const StudentProfile(
                profileId: 'u1',
                universityId: 'x',
                fullName: 'Sam Rivera',
                major: 'Computer Science',
                universityName: 'Springfield University'),
            verifiedSkills: skills,
          )),
          verificationRepositoryProvider.overrideWithValue(FakeVerificationRepository(
            sessions: [const VerificationSession(id: 'v1', step: VerificationStep.collectInput)],
          )),
          universityRepositoryProvider.overrideWithValue(FakeUniversityRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      );

  testWidgets('shows identity and cancelling the dialog does not sign out', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(host(auth));
    await tester.pumpAndSettle();

    expect(find.text('Sam Rivera'), findsOneWidget);
    expect(find.text('Computer Science'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of InternSpark?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(auth.signOutCount, 0);
  });

  testWidgets('confirming the dialog signs out', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(host(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-sign-out')));
    await tester.pumpAndSettle();

    expect(auth.signOutCount, 1);
  });

  testWidgets('sign-out error shows SnackBar and does not crash', (tester) async {
    final auth = FakeAuthRepository();
    auth.signOutError = Exception('Network error');
    await tester.pumpWidget(host(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-sign-out')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    // Verify the error message appears in the SnackBar
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data?.contains('Sign out failed') == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('verified skills render with provenance badges', (tester) async {
    await tester.pumpWidget(host(FakeAuthRepository(), skills: const [
      VerifiedSkill(
          skillId: 'k1', name: 'Python', source: SkillSource.curriculum,
          evidence: {'year': 1, 'semester': 2}),
      VerifiedSkill(
          skillId: 'k2', name: 'Java', source: SkillSource.certification,
          evidence: {'issuer': 'Coursera', 'issue_date': '2026-03-01'}),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Springfield University'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    expect(find.text('Curriculum · Y1S2'), findsOneWidget);
    expect(find.text('Certificate · Coursera · 2026'), findsOneWidget);
  });

  testWidgets('Update profile opens the verification wizard', (tester) async {
    await tester.pumpWidget(host(FakeAuthRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('update-profile')));
    await tester.pumpAndSettle();

    expect(find.text('Verify your skills'), findsOneWidget);
  });
}
