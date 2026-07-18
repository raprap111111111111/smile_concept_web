// lib/presentation/pages/clinical_records/widgets/quick_actions_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/../core/permissions/app_permissions.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../route/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class QuickActionsBar extends StatelessWidget {
  final AuthState auth;

  const QuickActionsBar({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[];

    if (auth.hasPermission(Perm.clinicalNoteCreate)) {
      actions.add(_QuickAction(
        icon: Icons.add_circle_outline,
        label: 'New Note',
        onTap: () => context.pushNamed(RouteNames.clinicalNoteCreate),
      ));
    }
    if (auth.hasPermission(Perm.prescriptionCreate)) {
      actions.add(_QuickAction(
        icon: Icons.medication_outlined,
        label: 'New Prescription',
        onTap: () => context.pushNamed(RouteNames.prescriptionCreate),
      ));
    }
    if (auth.hasPermission(Perm.labCaseCreate)) {
      actions.add(_QuickAction(
        icon: Icons.science_outlined,
        label: 'New Lab Case',
        onTap: () => context.pushNamed(RouteNames.labCaseCreate),
      ));
    }
    if (auth.hasPermission(Perm.attachmentUpload)) {
      actions.add(_QuickAction(
        icon: Icons.upload_file_outlined,
        label: 'Upload File',
        onTap: () => context.pushNamed(RouteNames.attachmentUpload),
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.paddingSmall),
          Wrap(
            spacing: AppDimensions.paddingSmall,
            runSpacing: AppDimensions.paddingSmall,
            children: actions
                .map((a) => _buildActionChip(a))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(_QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius:
          BorderRadius.circular(AppDimensions.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon,
                size: 18, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}