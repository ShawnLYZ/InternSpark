import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/roi_dashboard_screen.dart';

void main() {
  testWidgets('shows placement rate, the demand chart, and the gap list', (tester) async {
    final fake = FakeRoiRepository(
      summary: const RoiSummary(
        placementRate: 0.25,
        demand: [SkillDemand(skill: 'SQL', weight: 5), SkillDemand(skill: 'Docker', weight: 3)],
        gap: ['Docker'],
      ),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [roiRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: Scaffold(body: RoiDashboardScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('25%'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Docker'), findsOneWidget); // gap chip
  });
}
