import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/employer_shell.dart';
import 'package:app_web/src/university_shell.dart';

void main() {
  Future<void> signOutVia(WidgetTester tester, FakeAuthRepository auth) async {
    await tester.tap(find.byKey(const Key('account-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of InternSpark?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-sign-out')));
    await tester.pumpAndSettle();
    expect(auth.signOutCount, 1);
  }

  testWidgets('employer shell has a working account menu', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        employerRepositoryProvider.overrideWithValue(
            FakeEmployerRepository(company: const Company(id: 'c1', name: 'Nimbus Analytics'))),
        jobRepositoryProvider.overrideWithValue(FakeJobRepository()),
        leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository()),
      ],
      child: const MaterialApp(home: EmployerShell()),
    ));
    await tester.pumpAndSettle();
    await signOutVia(tester, auth);
  });

  testWidgets('university shell has a working account menu', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        universityRepositoryProvider.overrideWithValue(
            FakeUniversityRepository(university: const University(id: 'u1', name: 'Springfield University'))),
        roiRepositoryProvider.overrideWithValue(FakeRoiRepository()),
      ],
      child: const MaterialApp(home: UniversityShell()),
    ));
    await tester.pumpAndSettle();
    await signOutVia(tester, auth);
  });

  testWidgets('account menu shows error snackbar on sign-out failure', (tester) async {
    final auth = FakeAuthRepository()..signOutError = Exception('Network error');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        employerRepositoryProvider.overrideWithValue(
            FakeEmployerRepository(company: const Company(id: 'c1', name: 'Nimbus Analytics'))),
        jobRepositoryProvider.overrideWithValue(FakeJobRepository()),
        leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository()),
      ],
      child: const MaterialApp(home: EmployerShell()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of InternSpark?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-sign-out')));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Sign out failed: Exception: Network error'), findsOneWidget);
  });
}
