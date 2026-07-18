// lib/presentation/pages/inventory/widgets/inventory_empty_state.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class InventoryEmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const InventoryEmptyState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.accentWithOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            const Text(
              'No inventory items yet',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              'Start by adding stock items to your branches.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh,
                    size: AppDimensions.iconSizeSmall),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}