import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  testWidgets('gates small samples', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: GhostBadge(ghostRate: 0.0, totalMatches: 3)),
    ));
    expect(find.text('Not enough data'), findsOneWidget);
  });

  testWidgets('shows the percentage with enough data', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: GhostBadge(ghostRate: 0.25, totalMatches: 8)),
    ));
    expect(find.text('25% ghosted'), findsOneWidget);
  });
}
