// lib/presentation/pages/dashboard/components/charts/new_patients_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../data/models/dashboard/chart_series.dart';
import '../../../../theme/chart_palette.dart';

/// Patient registrations per month.
///
/// One series in one hue — the months are nominal buckets, so colouring them by
/// value would re-encode what bar height already shows. The latest month is
/// emphasised because it is the one the stat card counts.
class NewPatientsChart extends StatelessWidget {
  const NewPatientsChart({super.key, required this.points});

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
                    text:
                        '${point.count} new ${point.count == 1 ? 'patient' : 'patients'}',
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _gridInterval(maxY),
          getDrawingHorizontalLine: (_) => const FlLine(
            color: ChartPalette.gridline,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _gridInterval(maxY),
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: ChartPalette.axisText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    points[index].shortLabel,
                    style: TextStyle(
                      color: ChartPalette.axisText,
                      fontSize: 11,
                      fontWeight:
                          index == lastIndex ? FontWeight.w800 : FontWeight.w600,
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
                  width: 22,
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

  double _gridInterval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 12) return 2;
    if (maxY <= 30) return 5;
    return (maxY / 5).ceilToDouble();
  }
}
