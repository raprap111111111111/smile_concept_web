// lib/presentation/pages/consents/widgets/consent_filter_bar.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class ConsentFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const ConsentFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(
          label: 'All',
          active: selectedStatus == null,
          onTap: () => onStatusChanged(null),
          color: AppColors.primary,
        ),
        const SizedBox(width: AppDimensions.paddingXS),
        _chip(
          label: 'Valid',
          active: selectedStatus == 'valid',
          onTap: () => onStatusChanged('valid'),
          color: AppColors.success,
        ),
        const SizedBox(width: AppDimensions.paddingXS),
        _chip(
          label: 'Voided',
          active: selectedStatus == 'voided',
          onTap: () => onStatusChanged('voided'),
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: active ? color.withValues(alpha: 0.08) : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(
              color: active ? color : AppColors.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: active ? color : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}