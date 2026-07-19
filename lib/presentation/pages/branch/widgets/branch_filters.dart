import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class BranchFilters extends StatelessWidget {
  final String search;
  final bool? activeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool?> onActiveFilterChanged;

  const BranchFilters({
    super.key,
    required this.search,
    required this.activeFilter,
    required this.onSearchChanged,
    required this.onActiveFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, code, city, or province...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textTertiary,
                  size: AppDimensions.iconSize,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
        _filterChip(
          label: 'All',
          active: activeFilter == null,
          onTap: () => onActiveFilterChanged(null),
        ),
        const SizedBox(width: AppDimensions.paddingXS),
        _filterChip(
          label: 'Active',
          active: activeFilter == true,
          onTap: () => onActiveFilterChanged(true),
        ),
        const SizedBox(width: AppDimensions.paddingXS),
        _filterChip(
          label: 'Inactive',
          active: activeFilter == false,
          onTap: () => onActiveFilterChanged(false),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surface,
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
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: active ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}