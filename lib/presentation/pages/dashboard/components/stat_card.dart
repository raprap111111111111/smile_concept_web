// lib/presentation/pages/dashboard/components/stat_card.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import 'charts/sparkline.dart';

/// Stat tile: label · value · optional signed delta against a named period ·
/// optional sparkline. The number is the chart — no plot frame around it.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accentColor;
  final IconData? icon;

  /// Signed percentage change. Null hides the delta row.
  final double? delta;

  /// What the delta is measured against, e.g. "vs yesterday".
  final String? deltaPeriod;

  /// Whether an increase is the good direction — drives the delta colour.
  final bool upIsGood;

  /// Trend strip under the value; needs at least two points to draw.
  final List<int> trend;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.accentColor,
    this.icon,
    this.delta,
    this.deltaPeriod,
    this.upIsGood = true,
    this.trend = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _Delta(
                    delta: delta!,
                    period: deltaPeriod,
                    upIsGood: upIsGood,
                  ),
                ),
              ],
            ],
          ),
          if (trend.length >= 2) ...[
            const SizedBox(height: 10),
            Sparkline(values: trend, color: accentColor),
          ],
        ],
      ),
    );
  }
}

/// Direction is carried by an arrow as well as colour, so it never reads as
/// colour alone.
class _Delta extends StatelessWidget {
  const _Delta({
    required this.delta,
    required this.period,
    required this.upIsGood,
  });

  final double delta;
  final String? period;
  final bool upIsGood;

  @override
  Widget build(BuildContext context) {
    final isFlat = delta == 0;
    final isUp = delta > 0;
    final isGood = isUp == upIsGood;

    final color = isFlat
        ? AppColors.textTertiary
        : (isGood ? const Color(0xFF006300) : const Color(0xFFD03B3B));

    final icon = isFlat
        ? Icons.remove
        : (isUp ? Icons.arrow_upward : Icons.arrow_downward);

    final magnitude = delta.abs();
    final text =
        isFlat ? '0%' : '${magnitude.toStringAsFixed(magnitude < 10 ? 1 : 0)}%';

    return Tooltip(
      message: period == null ? text : '$text $period',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
