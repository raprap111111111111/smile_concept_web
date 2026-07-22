// lib/presentation/pages/dashboard/components/charts/activity_trend_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../data/models/dashboard/chart_series.dart';
import '../../../../theme/chart_palette.dart';

/// Recorded activity per day over the trailing two weeks — one series, one hue,
/// today emphasised.
class ActivityTrendChart extends StatelessWidget {
  const ActivityTrendChart({super.key, required this.points});

  final List<CountPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxCount = points.fold<int>(0, (max, p) => p.count > max ? p.count : max);
    final maxY = (maxCount == 0 ? 4 : maxCount + 1).toDouble();
    final lastIndex = points.length - 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ChartPalette.tooltipBackground,
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x];
              return BarTooltipItem(
                '${point.label}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '${point.count} ${point.count == 1 ? 'event' : 'events'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                // Only the ends are labelled — the tooltip carries the rest.
                if (index != 0 && index != lastIndex) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    index == lastIndex ? 'Today' : points[index].label,
                    style: const TextStyle(
                      color: ChartPalette.axisText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].count.toDouble(),
                  width: 8,
                  color: i == lastIndex
                      ? ChartPalette.primarySeries
                      : ChartPalette.deemphasis,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
