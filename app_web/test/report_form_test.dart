import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/report_form_screen.dart';

void main() {
  testWidgets('drafts then files a report', (tester) async {
    final fake = FakeReportRepository(students: const [
      ReportableStudent(studentId: 's1', fullName: 'Sam Rivera'),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: ReportFormScreen(companyName: 'Nimbus Analytics')),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<ReportableStudent>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sam Rivera').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'AI draft'));
    await tester.pumpAndSettle();
    expect(find.text('Drafted narrative for Sam Rivera.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('file-report')));
    await tester.pumpAndSettle();
    expect(fake.filed?['studentId'], 's1');
  });
}
