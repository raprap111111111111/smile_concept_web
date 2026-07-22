// lib/presentation/pages/dashboard/components/charts/appointments_trend_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../data/models/dashboard/chart_series.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/chart_palette.dart';

/// Total appointments booked per day over the trailing two weeks.
///
/// A single series — total bookings — so it takes one hue, an area wash, and no
/// legend box. Only the last point is direct-labelled; the axis and the hover
/// tooltip carry the rest.
class AppointmentsTrendChart extends StatelessWidget {
  const AppointmentsTrendChart({super.key, required this.points});

  final List<AppointmentTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxCount = points.fold<int>(0, (max, p) => p.total > max ? p.total : max);
    final maxY = (maxCount == 0 ? 4 : maxCount + 1).toDouble();
    final lastIndex = points.length - 1;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        minX: 0,
        maxX: lastIndex.toDouble(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => ChartPalette.tooltipBackground,
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final point = points[spot.x.toInt()];
                return LineTooltipItem(
                  '${point.label}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '${point.total} booked'
                          '${point.completed > 0 ? ' · ${point.completed} completed' : ''}'
                          '${point.cancelled > 0 ? ' · ${point.cancelled} cancelled' : ''}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (barData, indexes) {
            return indexes.map((_) {
              return TouchedSpotIndicatorData(
                const FlLine(color: ChartPalette.gridline, strokeWidth: 1),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 5,
                    color: ChartPalette.primarySeries,
                    // 2px ring in the surface colour keeps the dot legible
                    // wherever it crosses the line.
                    strokeWidth: 2,
                    strokeColor: ChartPalette.surface,
                  ),
                ),
              );
            }).toList();
          },
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
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                // Every third day keeps the axis readable on narrow cards.
                if (index % 3 != 0 && index != lastIndex) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    points[index].label,
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
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].total.toDouble()),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: ChartPalette.primarySeries,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              // Only the final point carries a marker; it is the one labelled.
              checkToShowDot: (spot, barData) => spot.x == lastIndex.toDouble(),
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: ChartPalette.primarySeries,
                strokeWidth: 2,
                strokeColor: ChartPalette.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: ChartPalette.primarySeriesWash,
            ),
          ),
        ],
        showingTooltipIndicators: const [],
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

/// Caption under the trend chart — names the single series and its latest
/// value, which is why the chart itself needs no legend box.
class TrendCaption extends StatelessWidget {
  const TrendCaption({super.key, required this.points});

  final List<AppointmentTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final total = points.fold<int>(0, (sum, p) => sum + p.total);
    final completed = points.fold<int>(0, (sum, p) => sum + p.completed);
    final cancelled = points.fold<int>(0, (sum, p) => sum + p.cancelled);

    return Wrap(
      spacing: 18,
      runSpacing: 6,
      children: [
        _Fact(label: 'Booked', value: '$total'),
        _Fact(label: 'Completed', value: '$completed'),
        _Fact(label: 'Cancelled', value: '$cancelled'),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
