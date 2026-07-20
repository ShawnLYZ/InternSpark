import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/credit_queue_screen.dart';

void main() {
  testWidgets('generate a mapping then approve with a signer', (tester) async {
    final fake = FakeCreditRepository(requests: const [
      CreditRequest(id: 'cr1', status: 'pending', jobId: 'j1', jobTitle: 'Data Analyst Intern', studentName: 'Sam Rivera'),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [creditRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: CreditQueueScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('generate')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Satisfies 1 core requirement'), findsOneWidget);
    expect(fake.attached, isNotNull);

    await tester.enterText(find.widgetWithText(TextField, 'Signer name'), 'Dr. Lee');
    await tester.tap(find.byKey(const Key('approve')));
    await tester.pumpAndSettle();
    expect(fake.approved?['signer'], 'Dr. Lee');
  });
}
