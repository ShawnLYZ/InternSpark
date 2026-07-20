import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  testWidgets('renders a bar chart for demand data', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DemandBarChart(demand: [
        SkillDemand(skill: 'SQL', weight: 5),
        SkillDemand(skill: 'Python', weight: 4),
      ], gap: {'Python'})),
    ));
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('SQL'), findsOneWidget);
  });

  testWidgets('empty demand shows a fallback', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DemandBarChart(demand: []))));
    expect(find.text('No demand data'), findsOneWidget);
  });
}
