// lib/presentation/pages/users/widgets/user_filters.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class UserFilters extends StatelessWidget {
  final String search;
  final String? roleFilter;
  final AsyncValue<List<Map<String, dynamic>>> rolesAsync;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onRoleChanged;

  const UserFilters({
    super.key,
    required this.search,
    required this.roleFilter,
    required this.rolesAsync,
    required this.onSearchChanged,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Search ──────────────────────────────────
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textTertiary,
                  size: AppDimensions.iconSizeMedium,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingSmall),

        // ── Role dropdown ────────────────────────────
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: rolesAsync.when(
              data: (roles) => DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: roleFilter,
                  isExpanded: true,
                  dropdownColor: AppColors.background,
                  hint: Text(
                    'All Roles',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  icon: const Icon(
                    Icons.filter_list_rounded,
                    color: AppColors.textTertiary,
                    size: AppDimensions.iconSizeMedium,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'All Roles',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ...roles.map((role) {
                      final name = role['name']?.toString() ?? '';
                      return DropdownMenuItem<String?>(
                        value: name,
                        child: Text(
                          name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: onRoleChanged,
                ),
              ),
              loading: () => const SizedBox(
                height: 2,
                child: LinearProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => Text(
                'Failed to load roles',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}