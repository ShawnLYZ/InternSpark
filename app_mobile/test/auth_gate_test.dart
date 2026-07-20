import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/main.dart';

void main() {
  testWidgets('signed-out shows the login screen', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [currentProfileProvider.overrideWith((ref) async => null)],
      child: const InternSparkMobileApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('a non-student is told to use the web app', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => const Profile(id: 'e1', role: UserRole.employer)),
      ],
      child: const InternSparkMobileApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('web app'), findsOneWidget);
  });

  testWidgets('a student without a profile row is routed into the wizard', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => const Profile(id: 's1', role: UserRole.student)),
        studentRepositoryProvider.overrideWithValue(FakeStudentRepository()),
        verificationRepositoryProvider.overrideWithValue(FakeVerificationRepository(
          sessions: [const VerificationSession(id: 'v1', step: VerificationStep.collectInput)],
        )),
        universityRepositoryProvider.overrideWithValue(FakeUniversityRepository()),
      ],
      child: const InternSparkMobileApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Verify your skills'), findsOneWidget);
  });

  testWidgets('an onboarded student with no active session lands in the shell', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => const Profile(id: 's1', role: UserRole.student)),
        studentRepositoryProvider.overrideWithValue(FakeStudentRepository(
          studentProfile: const StudentProfile(profileId: 's1', universityId: 'u1', fullName: 'Sam Rivera'),
        )),
        verificationRepositoryProvider.overrideWithValue(FakeVerificationRepository(hasActive: false)),
      ],
      child: const InternSparkMobileApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
