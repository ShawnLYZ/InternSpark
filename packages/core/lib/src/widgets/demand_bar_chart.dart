import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../design/app_tokens.dart';
import '../domain/roi.dart';

/// The one InternSpark chart (fl_chart). A labelled bar chart of the top
/// market-demand skills; [gap] skills are highlighted in warning amber.
class DemandBarChart extends StatelessWidget {
  const DemandBarChart({super.key, required this.demand, this.gap = const {}, this.maxBars = 6});
  final List<SkillDemand> demand;
  final Set<String> gap;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bars = demand.take(maxBars).toList();
    if (bars.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text('No demand data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      );
    }
    final maxY = bars.first.weight;
    final lowered = gap.map((g) => g.toLowerCase()).toSet();

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: maxY + 1,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < bars.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: bars[i].weight,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSm)),
                  color: lowered.contains(bars[i].skill.toLowerCase())
                      ? AppTokens.warning
                      : scheme.primary,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY + 1,
                    color: scheme.surfaceContainerHighest,
                  ),
                ),
              ]),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(bars[i].skill,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
