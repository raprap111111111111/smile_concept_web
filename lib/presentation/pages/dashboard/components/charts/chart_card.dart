// lib/presentation/pages/dashboard/components/charts/chart_card.dart
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_dimensions.dart';
import '../../../../theme/app_text_styles.dart';

/// Shared shell for every dashboard chart: title, a subtitle that names what is
/// plotted (so a single-series chart needs no legend box), optional trailing
/// widget, and the plot itself at a fixed height.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.footer,
    this.height = 200,
    this.isEmpty = false,
    this.emptyMessage = 'No data for this period',
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final Widget? footer;
  final double height;
  final bool isEmpty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: height,
            child: isEmpty
                ? Center(
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : child,
          ),
          if (footer != null) ...[
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Signed percentage change against a named period. Direction is carried by an
/// arrow icon as well as colour, so it never reads as colour alone.
class DeltaBadge extends StatelessWidget {
  const DeltaBadge({
    super.key,
    required this.delta,
    required this.period,
    this.upIsGood = true,
  });

  final double delta;
  final String period;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              isFlat ? '0%' : '${delta.abs().toStringAsFixed(delta.abs() < 10 ? 1 : 0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          period,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
