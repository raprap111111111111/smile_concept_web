// lib/presentation/pages/prescriptions/widgets/prescription_item_tile.dart

import 'package:flutter/material.dart';
import '../../../../data/models/prescription/prescription_item_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class PrescriptionItemTile extends StatelessWidget {
  final PrescriptionItemModel item;
  final int index;

  const PrescriptionItemTile({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                    AppDimensions.borderRadiusLarge),
                topRight: Radius.circular(
                    AppDimensions.borderRadiusLarge),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.medicineName,
                    style: AppTextStyles.labelLarge,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.line, height: 1),

          // ── Details ───────────────────────────────
          Padding(
            padding:
                const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DetailPill(
                        icon: Icons.local_pharmacy_outlined,
                        label: 'Dosage',
                        value: item.dosage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DetailPill(
                        icon: Icons.access_time_outlined,
                        label: 'Frequency',
                        value: item.frequency,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _DetailPill(
                  icon: Icons.calendar_month_outlined,
                  label: 'Duration',
                  value: item.durationLabel,
                  fullWidth: true,
                ),

                if (item.hasInstructions) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                        AppDimensions.paddingSmall + 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentWithOpacity(0.08),
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadius),
                      border: const Border(
                        left: BorderSide(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.instructions!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Pill ───────────────────────────────────────────
class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _DetailPill({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}