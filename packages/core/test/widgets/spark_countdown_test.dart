import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  testWidgets('shows remaining time from the injected clock', (tester) async {
    final deadline = DateTime.utc(2026, 7, 8, 12);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SparkCountdown(deadline: deadline, clock: () => DateTime.utc(2026, 7, 2, 12))),
    ));
    expect(find.text('6d 0h left'), findsOneWidget);
  });

  testWidgets('shows Expired past the deadline', (tester) async {
    final deadline = DateTime.utc(2026, 7, 8, 12);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SparkCountdown(deadline: deadline, clock: () => DateTime.utc(2026, 7, 9))),
    ));
    expect(find.text('Expired'), findsOneWidget);
  });
}
