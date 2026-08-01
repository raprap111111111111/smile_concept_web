// lib/presentation/pages/lab_cases/widgets/lab_case_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smile_concept_web/core/permissions/app_permissions.dart';
import 'package:smile_concept_web/presentation/widgets/common/permission_gate.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/theme/app_dimensions.dart';
import 'package:smile_concept_web/presentation/theme/app_text_styles.dart';
import 'package:smile_concept_web/data/models/lab_case/lab_case_model.dart';
import 'package:smile_concept_web/presentation/pages/lab_cases/widgets/lab_case_status_badge.dart';
import 'package:smile_concept_web/presentation/route/route_names.dart';
import 'package:smile_concept_web/presentation/widgets/shared/hold_to_delete_dialog.dart';

class LabCaseCard extends ConsumerWidget {
  final LabCaseModel labCase;
  final VoidCallback? onDeleted;

  const LabCaseCard({
    super.key,
    required this.labCase,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.labCaseEdit,
          pathParameters: {'id': labCase.id.toString()},
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                child: Icon(
                  Icons.science_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      labCase.labName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Work type
                    Text(
                      labCase.workType,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    // Info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.event_outlined,
                          text:
                              'Due ${DateFormat('MMM d').format(labCase.dueDate)}',
                          color: labCase.isOverdue
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                        if (labCase.patientName != null)
                          _InfoChip(
                            icon: Icons.person_outline,
                            text: labCase.patientName!,
                            color: const Color(0xFF6366F1),
                          ),
                        if (labCase.cost != null)
                          _InfoChip(
                            icon: Icons.attach_money_outlined,
                            text: NumberFormat.currency(
                                    symbol: '\$', decimalDigits: 2)
                                .format(labCase.cost),
                            color: AppColors.success,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimensions.paddingMedium),

              // Right side: status badge + delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LabCaseStatusBadge(status: labCase.status),
                  const SizedBox(height: 8),
                  PermissionGate(
                    permission: Perm.labCaseDelete,
                    child: InkWell(
                      onTap: () => _confirmDelete(context, ref),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete Lab Case',
      itemName: labCase.labName,
      description:
          'This will permanently remove the lab case for "${labCase.labName}".',
    );
    if (confirmed == true) {
      onDeleted?.call();
    }
  }
}

// ── Colored info chip (matches Inventory style) ────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}