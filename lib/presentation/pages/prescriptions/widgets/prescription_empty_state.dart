// lib/presentation/pages/prescriptions/widgets/prescription_empty_state.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class PrescriptionEmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const PrescriptionEmptyState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Illustration ───────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.accentWithOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.accentWithOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.medication_outlined,
                  size: 44,
                  color: AppColors.primaryDark,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            const Text(
              'No Prescriptions Yet',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 320,
              child: Text(
                'Your prescriptions will appear here once your '
                'doctor adds them.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: AppDimensions.paddingLarge),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}