// lib/presentation/pages/inventory/widgets/inventory_stats_bar.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class InventoryStatsBar extends StatelessWidget {
  final int total;
  final int lowStock;
  final int expired;

  const InventoryStatsBar({
    super.key,
    required this.total,
    required this.lowStock,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Total',
            count: total,
            icon: Icons.inventory_2_outlined,
            color: AppColors.info,
          ),
          _Divider(),
          _StatItem(
            label: 'Low Stock',
            count: lowStock,
            icon: Icons.trending_down,
            color: AppColors.warning,
          ),
          _Divider(),
          _StatItem(
            label: 'Expired',
            count: expired,
            icon: Icons.warning_amber_rounded,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppDimensions.iconSizeSmall, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.divider,
    );
  }
}