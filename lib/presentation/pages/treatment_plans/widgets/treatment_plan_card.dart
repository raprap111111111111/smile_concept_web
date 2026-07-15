// lib/presentation/pages/treatment_plans/widgets/treatment_plan_card.dart
import 'package:flutter/material.dart';

import '../../../../data/models/treatment/treatment_plan_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class TreatmentPlanCard extends StatelessWidget {
  final TreatmentPlanModel plan;
  final bool canDelete;
  final bool canChangeStatus;
  final VoidCallback onDelete;
  final VoidCallback onChangeStatus;

  const TreatmentPlanCard({
    super.key,
    required this.plan,
    required this.canDelete,
    required this.canChangeStatus,
    required this.onDelete,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ─────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentWithOpacity(0.22),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.primaryDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            plan.patient?.name ?? 'Unknown patient',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: plan.status),
              ],
            ),
          ),

          const Divider(color: AppColors.line, height: 1),

          // ─── Body: Meta info ────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                _MetaRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Doctor',
                  value: plan.doctor?.name ?? 'Unassigned Doctor',
                ),
                const SizedBox(height: 10),
                _MetaRow(
                  icon: Icons.format_list_numbered,
                  label: 'Items',
                  value:
                      '${plan.items.length} treatment step${plan.items.length == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 10),
                _MetaRow(
                  icon: Icons.payments_outlined,
                  label: 'Total',
                  value:
                      '\$${(plan.totalEstimatedAmount).toStringAsFixed(2)}',
                  valueColor: AppColors.primaryDark,
                  valueBold: true,
                ),
                if (plan.notes != null && plan.notes!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                    child: Text(
                      plan.notes!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── Actions ────────────────────────
          if (canDelete || canChangeStatus) ...[
            const Divider(color: AppColors.line, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canChangeStatus)
                    TextButton.icon(
                      onPressed: onChangeStatus,
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('Change Status'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (canDelete) ...[
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.ink,
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _capitalize(status),
            style: TextStyle(
              color: config.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _configFor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return _StatusConfig(
          bg: AppColors.textTertiary.withValues(alpha: 0.12),
          border: AppColors.textTertiary.withValues(alpha: 0.3),
          text: AppColors.textSecondary,
          dot: AppColors.textTertiary,
        );
      case 'proposed':
        return _StatusConfig(
          bg: AppColors.info.withValues(alpha: 0.12),
          border: AppColors.info.withValues(alpha: 0.3),
          text: AppColors.info,
          dot: AppColors.info,
        );
      case 'accepted':
        return _StatusConfig(
          bg: AppColors.primary.withValues(alpha: 0.14),
          border: AppColors.primary.withValues(alpha: 0.3),
          text: AppColors.primaryDark,
          dot: AppColors.primary,
        );
      case 'completed':
        return _StatusConfig(
          bg: AppColors.success.withValues(alpha: 0.12),
          border: AppColors.success.withValues(alpha: 0.3),
          text: AppColors.success,
          dot: AppColors.success,
        );
      case 'rejected':
        return _StatusConfig(
          bg: AppColors.error.withValues(alpha: 0.10),
          border: AppColors.error.withValues(alpha: 0.3),
          text: AppColors.error,
          dot: AppColors.error,
        );
      default:
        return _StatusConfig(
          bg: AppColors.surface,
          border: AppColors.line,
          text: AppColors.textSecondary,
          dot: AppColors.textTertiary,
        );
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatusConfig {
  final Color bg;
  final Color border;
  final Color text;
  final Color dot;

  _StatusConfig({
    required this.bg,
    required this.border,
    required this.text,
    required this.dot,
  });
}
