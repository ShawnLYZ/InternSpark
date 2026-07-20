import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/job_form_screen.dart';

void main() {
  testWidgets('AI draft fills growth_text; save sends the values', (tester) async {
    final fake = FakeJobRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [jobRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: JobFormScreen()),
    ));
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Data Analyst Intern');

    await tester.tap(find.widgetWithText(TextButton, 'AI draft'));
    await tester.pumpAndSettle();
    expect(find.text('Draft growth blurb for Data Analyst Intern.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save job'));
    await tester.pumpAndSettle();
    expect(fake.lastUpsert?['title'], 'Data Analyst Intern');
    expect(fake.lastUpsert?['growth_text'], 'Draft growth blurb for Data Analyst Intern.');
  });
}
