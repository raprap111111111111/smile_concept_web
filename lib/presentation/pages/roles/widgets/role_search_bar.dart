// lib/presentation/pages/roles/widgets/role_search_bar.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class RoleSearchBar extends StatelessWidget {
  final String search;
  final ValueChanged<String> onChanged;

  const RoleSearchBar({
    super.key,
    required this.search,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = search.isNotEmpty;

    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search roles...',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textTertiary,
          size: AppDimensions.iconSizeMedium,
        ),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  size: AppDimensions.iconSizeSmall,
                  color: AppColors.textTertiary,
                ),
                tooltip: 'Clear search',
                onPressed: () => onChanged(''),
              )
            : null,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}