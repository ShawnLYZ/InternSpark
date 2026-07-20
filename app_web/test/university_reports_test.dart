import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/university_reports_screen.dart';

void main() {
  testWidgets('lists reports received', (tester) async {
    final fake = FakeReportRepository(reports: const [
      Report(reliability: 5, skill: 4, communication: 5, studentName: 'Sam Rivera',
          companyName: 'Nimbus Analytics', narrative: 'Owned a metric end to end.'),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: UniversityReportsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sam Rivera'), findsOneWidget);
    expect(find.textContaining('Owned a metric'), findsOneWidget);
  });
}
