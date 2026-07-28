// lib/presentation/pages/treatments/widgets/treatment_card.dart

import 'package:flutter/material.dart';
import '../../../../data/models/treatment/treatment_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import 'treatment_info_chip.dart';

class TreatmentCard extends StatelessWidget {
  final TreatmentModel treatment;
  final bool canDelete;
  final VoidCallback onDelete;

  const TreatmentCard({
    super.key,
    required this.treatment,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.cardPaddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──────────────────────────────────
            _TreatmentAvatar(isActive: treatment.isActive),
            const SizedBox(width: AppDimensions.paddingSmall),

            // ── Info ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    treatment.name,
                    style: AppTextStyles.titleSmall,
                  ),
                  if (treatment.description != null &&
                      treatment.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      treatment.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.paddingXS),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      TreatmentInfoChip(
                        label: treatment.formattedPrice,
                        icon: Icons.payments_rounded,
                        color: AppColors.success,
                      ),
                      TreatmentInfoChip(
                        label: treatment.durationLabel,
                        icon: Icons.timer_rounded,
                        color: AppColors.primary,
                      ),
                      TreatmentInfoChip(
                        label: treatment.isActive ? 'Active' : 'Inactive',
                        icon: treatment.isActive
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: treatment.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Delete ──────────────────────────────────
            if (canDelete) ...[
              const SizedBox(width: AppDimensions.paddingXS),
              _DeleteButton(onPressed: onDelete),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _TreatmentAvatar extends StatelessWidget {
  const _TreatmentAvatar({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryWithOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: const Icon(
        Icons.medical_services_rounded,
        color: AppColors.primary,
        size: AppDimensions.iconSize,
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Delete treatment',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.15),
            ),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: AppDimensions.iconSizeSmall,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}