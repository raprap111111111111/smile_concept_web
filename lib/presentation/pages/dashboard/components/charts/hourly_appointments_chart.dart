// lib/presentation/pages/dashboard/components/charts/hourly_appointments_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../data/models/dashboard/chart_series.dart';
import '../../../../theme/chart_palette.dart';

/// When today's appointments start, hour by hour.
///
/// One series, so it takes a single hue and no legend — the card title names
/// what is plotted. The hour the clinic is currently in is the emphasised bar;
/// every other hour recedes, which is the "emphasis" form rather than a
/// value-ramp (bar height already encodes the count).
class HourlyAppointmentsChart extends StatelessWidget {
  const HourlyAppointmentsChart({
    super.key,
    required this.points,
    this.highlightHour,
  });

  final List<HourlyPoint> points;

  /// Hour to emphasise; defaults to the current hour.
  final int? highlightHour;

  @override
  Widget build(BuildContext context) {
    final currentHour = highlightHour ?? DateTime.now().hour;
    final maxCount = points.fold<int>(0, (max, p) => p.count > max ? p.count : max);
    // Keep a headroom of one so the tallest bar never touches the top gridline.
    final maxY = (maxCount == 0 ? 4 : maxCount + 1).toDouble();

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
              final count = point.count;
              return BarTooltipItem(
                '${point.label}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '$count ${count == 1 ? 'appointment' : 'appointments'}',
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
                // Label every other hour so ticks never collide.
                if (index.isOdd) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    points[index].label.replaceAll(' ', ''),
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
                  width: 14,
                  color: points[i].hour == currentHour
                      ? ChartPalette.primarySeries
                      : ChartPalette.deemphasis,
                  // Rounded data-end, square where it meets the baseline.
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
