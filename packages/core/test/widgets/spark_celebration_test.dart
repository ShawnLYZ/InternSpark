import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  testWidgets('animates in and shows the company', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SparkCelebration(company: 'Nimbus'))));
    expect(find.text("It's a Spark!"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100)); // mid-animation
    await tester.pumpAndSettle();                          // settles the controller
    expect(find.text('You matched with Nimbus.'), findsOneWidget);
  });
}
