import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/employer_shell.dart';

void main() {
  testWidgets('employer shell lists jobs and the company name', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        employerRepositoryProvider.overrideWithValue(
          FakeEmployerRepository(company: const Company(id: 'c1', name: 'Nimbus Analytics'))),
        jobRepositoryProvider.overrideWithValue(
          FakeJobRepository(jobs: const [Job(id: 'j1', companyId: 'c1', title: 'Data Analyst Intern')])),
        leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository()),
      ],
      child: const MaterialApp(home: EmployerShell()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nimbus Analytics'), findsOneWidget);
    expect(find.text('Data Analyst Intern'), findsOneWidget);
  });
}
