import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/student_shell.dart';

void main() {
  testWidgets('Home shows name + job count through the (fake) repository', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        studentRepositoryProvider.overrideWithValue(
          FakeStudentRepository(
            studentProfile: const StudentProfile(profileId: 'u1', universityId: 'x', fullName: 'Sam Rivera'),
            jobCount: 5,
          ),
        ),
      ],
      child: const MaterialApp(home: StudentShell()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Sam Rivera'), findsOneWidget);
    expect(find.text('5 internships available'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
