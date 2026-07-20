import 'package:flutter/material.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_text_styles.dart';
import '/presentation//theme/app_dimensions.dart';

class AccessDeniedView extends StatelessWidget {
  final VoidCallback? onBack;

  const AccessDeniedView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text(
              'Access Denied',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'You do not have permission to create prescriptions.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onBack != null) ...[
              const SizedBox(height: AppDimensions.paddingLarge),
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Go Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}