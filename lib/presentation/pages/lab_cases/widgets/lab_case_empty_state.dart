// lib/presentation/pages/lab_cases/widgets/lab_case_empty_state.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smile_concept_web/core/permissions/app_permissions.dart';
import 'package:smile_concept_web/presentation/widgets/common/permission_gate.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/theme/app_dimensions.dart';
import 'package:smile_concept_web/presentation/theme/app_text_styles.dart';
import 'package:smile_concept_web/presentation/route/route_names.dart';

class LabCaseEmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback? onResetFilters;

  const LabCaseEmptyState({
    super.key,
    this.hasFilters = false,
    this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    // Use SingleChildScrollView so it never overflows regardless of parent height
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingXL,
          vertical: AppDimensions.paddingLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.search_off_outlined
                    : Icons.science_outlined,
                size: 36,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              hasFilters ? 'No matching lab cases' : 'No lab cases yet',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters.'
                  : 'Create your first lab case to start tracking dental work sent to external laboratories.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('Clear Filters'),
              )
            else
              PermissionGate(
                permission: Perm.labCaseCreate,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.pushNamed(RouteNames.labCaseCreate),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Lab Case'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}