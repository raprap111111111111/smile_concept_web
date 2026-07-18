// lib/presentation/pages/inventory/widgets/inventory_card.dart

import 'package:flutter/material.dart';
import '../../../../data/models/inventory/inventory_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class InventoryCard extends StatelessWidget {
  final InventoryModel inventory;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const InventoryCard({
    super.key,
    required this.inventory,
    this.canDelete = false,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = inventory.item;
    final branch = inventory.branch;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(
          color: _borderColor,
          width: inventory.isLowStock || inventory.isExpired ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon Badge ─────────────────────────
                Container(
                  width: AppDimensions.iconBadgeSize,
                  height: AppDimensions.iconBadgeSize,
                  decoration: BoxDecoration(
                    color: _iconBgColor,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: _iconColor,
                    size: AppDimensions.iconSize,
                  ),
                ),

                const SizedBox(width: AppDimensions.paddingSmall),

                // ── Details ────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Status Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item?.name ?? 'Unknown Item',
                              style: AppTextStyles.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(inventory: inventory),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // SKU
                      if (item?.sku != null)
                        Text(
                          'SKU: ${item!.sku}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                      const SizedBox(height: AppDimensions.paddingXS),

                      // Info Chips Row
                      Wrap(
                        spacing: AppDimensions.paddingXS,
                        runSpacing: 4,
                        children: [
                          _InfoChip(
                            icon: Icons.numbers,
                            label: inventory.quantityLabel,
                            color: _quantityColor,
                          ),
                          if (branch != null)
                            _InfoChip(
                              icon: Icons.location_on_outlined,
                              label: branch.name,
                              color: AppColors.textSecondary,
                            ),
                          if (item?.category != null)
                            _InfoChip(
                              icon: Icons.category_outlined,
                              label: item!.category!,
                              color: AppColors.primary,
                            ),
                        ],
                      ),

                      // Expiry
                      if (inventory.expiryDate != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: inventory.isExpired
                                  ? AppColors.error
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Expires: ${inventory.expiryDate}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: inventory.isExpired
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                fontWeight: inventory.isExpired
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Delete ─────────────────────────────
                if (canDelete)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.error.withOpacity(0.7),
                    iconSize: AppDimensions.iconSizeMedium,
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _borderColor {
    if (inventory.isExpired) return AppColors.error.withOpacity(0.4);
    if (inventory.isLowStock) return AppColors.warning.withOpacity(0.4);
    return AppColors.border;
  }

  Color get _iconBgColor {
    if (inventory.isExpired) return AppColors.error.withOpacity(0.08);
    if (inventory.isLowStock) return AppColors.warning.withOpacity(0.08);
    return AppColors.accentWithOpacity(0.12);
  }

  Color get _iconColor {
    if (inventory.isExpired) return AppColors.error;
    if (inventory.isLowStock) return AppColors.warning;
    return AppColors.primary;
  }

  Color get _quantityColor {
    if (inventory.isExpired) return AppColors.error;
    if (inventory.isLowStock) return AppColors.warning;
    return AppColors.success;
  }
}

// ── Status Badge ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final InventoryModel inventory;
  const _StatusBadge({required this.inventory});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (inventory.isExpired) {
      color = AppColors.error;
      icon = Icons.warning_amber_rounded;
    } else if (inventory.isLowStock) {
      color = AppColors.warning;
      icon = Icons.trending_down;
    } else {
      color = AppColors.success;
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            inventory.stockStatusLabel,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}