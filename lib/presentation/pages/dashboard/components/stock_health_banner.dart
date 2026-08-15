// lib/presentation/pages/dashboard/components/stock_health_banner.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/dashboard/dashboard_stats.dart';
import '../../../route/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// Supply problems worth interrupting the dashboard for.
///
/// Deliberately not three more stat tiles. The four headline tiles answer "how
/// is the clinic doing today"; stock is a different question, and it is only
/// worth screen space when something is actually wrong — so this renders
/// nothing at all when the cupboard is healthy.
///
/// Each count carries an icon as well as a colour: the house chart rule is that
/// state is never encoded by colour alone.
class StockHealthBanner extends StatelessWidget {
  final DashboardStats stats;

  const StockHealthBanner({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (!stats.hasStockWarnings) {
      return const SizedBox.shrink();
    }

    // Negative stock is the most serious: it means supplies were used that
    // nobody had recorded, so it leads.
    final entries = <_StockWarning>[
      if (stats.negativeStock > 0)
        _StockWarning(
          icon: Icons.error_outline,
          color: AppColors.error,
          count: stats.negativeStock,
          singular: 'item is over-used',
          plural: 'items are over-used',
        ),
      if (stats.lowStockItems > 0)
        _StockWarning(
          icon: Icons.trending_down,
          color: AppColors.warning,
          count: stats.lowStockItems,
          singular: 'item needs reordering',
          plural: 'items need reordering',
        ),
      if (stats.expiringBatches > 0)
        _StockWarning(
          icon: Icons.schedule_outlined,
          color: AppColors.warning,
          count: stats.expiringBatches,
          singular: 'batch is expiring',
          plural: 'batches are expiring',
        ),
    ];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        onTap: () => context.pushNamed(RouteNames.inventory),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.warning,
                size: AppDimensions.iconSize,
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock needs attention',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppDimensions.paddingMedium,
                      runSpacing: 6,
                      children: entries
                          .map((entry) => _WarningChip(warning: entry))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: AppDimensions.iconSizeMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockWarning {
  final IconData icon;
  final Color color;
  final int count;
  final String singular;
  final String plural;

  const _StockWarning({
    required this.icon,
    required this.color,
    required this.count,
    required this.singular,
    required this.plural,
  });

  String get label => '$count ${count == 1 ? singular : plural}';
}

class _WarningChip extends StatelessWidget {
  final _StockWarning warning;

  const _WarningChip({required this.warning});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(warning.icon, size: 14, color: warning.color),
        const SizedBox(width: 5),
        Text(
          warning.label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
