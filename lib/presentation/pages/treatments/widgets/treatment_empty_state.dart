// lib/presentation/pages/treatments/widgets/treatment_empty_state.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class TreatmentEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const TreatmentEmptyState({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icon container ──────────────────────────
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.06),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
                border: Border.all(
                  color: AppColors.primaryWithOpacity(0.12),
                ),
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                size: 40,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Title ───────────────────────────────────
            Text(
              'No Treatments Found',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingXS),

            // ── Subtitle ────────────────────────────────
            Text(
              'No treatment catalog entries yet.\n'
              'Add treatments to get started.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Refresh button ──────────────────────────
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(
                Icons.refresh_rounded,
                size: AppDimensions.iconSizeSmall,
              ),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                ),
                textStyle: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}