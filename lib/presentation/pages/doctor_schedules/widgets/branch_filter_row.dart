// lib/presentation/pages/doctor_schedules/widgets/branch_filter_row.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_message.dart';
import '../../../providers/doctor_schedule/schedule_form_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Horizontal pill row mirroring [DayFilterRow], so the two filters on the
/// schedules page read as one control strip rather than two unrelated widgets.
///
/// Selecting nothing means "All Branches" — the page then sends no `branch_id`
/// and the endpoint returns every branch.
class BranchFilterRow extends ConsumerWidget {
  final int? selectedBranchId;
  final ValueChanged<int?> onChanged;

  const BranchFilterRow({
    super.key,
    required this.selectedBranchId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesListProvider);

    return branchesAsync.when(
      loading: () => const _FilterMessage(
        icon: Icons.hourglass_empty,
        message: 'Loading branches...',
      ),
      error: (e, _) => _FilterMessage(
        icon: Icons.error_outline,
        message: describeError(e),
        isError: true,
        // A 403 is settled server-side; retrying only repeats it.
        onRetry: isPermissionError(e)
            ? null
            : () => ref.invalidate(branchesListProvider),
      ),
      data: (branches) {
        if (branches.isEmpty) {
          return const _FilterMessage(
            icon: Icons.info_outline,
            message: 'No branches available',
          );
        }

        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _BranchChip(
                label: 'All Branches',
                icon: Icons.apartment_rounded,
                isSelected: selectedBranchId == null,
                onTap: () => onChanged(null),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: AppColors.border,
              ),
              const SizedBox(width: 8),
              ...branches.map((branch) {
                final isSelected = selectedBranchId == branch.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _BranchChip(
                    label: branch.name,
                    icon: Icons.location_on_outlined,
                    isSelected: isSelected,
                    // Tapping the active branch clears it, matching how the
                    // day pills toggle off.
                    onTap: () => onChanged(isSelected ? null : branch.id),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// BRANCH CHIP
// ─────────────────────────────────────────────────────────
class _BranchChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BranchChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
              // Branch names run long ("Bacolod Main Branch"), so the pill is
              // capped and ellipsised rather than pushing the row wider.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// LOADING / ERROR / EMPTY PLACEHOLDER
// ─────────────────────────────────────────────────────────
class _FilterMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  const _FilterMessage({
    required this.icon,
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.textMuted;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 4),
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
