// lib/presentation/widgets/shared/branch_filter_chips.dart

import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// One branch in the filter strip.
///
/// Deliberately its own tiny type rather than any of the branch models: the
/// schedules page and the inventory page each fetch branches through a
/// different provider returning a different shape, and the strip only ever
/// needs an id and a label.
class BranchFilterOption {
  final int id;
  final String name;

  const BranchFilterOption({required this.id, required this.name});
}

/// Horizontal pill row for filtering by branch, with its own loading, error and
/// empty states.
///
/// Presentational: it takes an [AsyncValue] rather than watching a provider, so
/// the same strip serves any page regardless of where its branches come from.
/// Selecting nothing means "All Branches" — the caller then sends no
/// `branch_id`.
class BranchFilterChips extends StatelessWidget {
  final AsyncValueLike<List<BranchFilterOption>> branches;
  final int? selectedBranchId;
  final ValueChanged<int?> onChanged;
  final VoidCallback? onRetry;

  const BranchFilterChips({
    super.key,
    required this.branches,
    required this.selectedBranchId,
    required this.onChanged,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final error = branches.error;

    if (branches.isLoading) {
      return const _FilterMessage(
        icon: Icons.hourglass_empty,
        message: 'Loading branches...',
      );
    }

    if (error != null) {
      return _FilterMessage(
        icon: Icons.error_outline,
        message: describeError(error),
        isError: true,
        // A 403 is settled server-side; retrying only repeats it.
        onRetry: isPermissionError(error) ? null : onRetry,
      );
    }

    final items = branches.value ?? const <BranchFilterOption>[];

    if (items.isEmpty) {
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
          ...items.map((branch) {
            final isSelected = selectedBranchId == branch.id;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _BranchChip(
                label: branch.name,
                icon: Icons.location_on_outlined,
                isSelected: isSelected,
                // Tapping the active branch clears it, matching how the day
                // pills toggle off.
                onTap: () => onChanged(isSelected ? null : branch.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// The three fields this strip needs off an `AsyncValue`, without dragging a
/// Riverpod dependency into a presentational widget.
class AsyncValueLike<T> {
  final T? value;
  final Object? error;
  final bool isLoading;

  const AsyncValueLike({this.value, this.error, this.isLoading = false});

  const AsyncValueLike.loading() : this(isLoading: true);
  const AsyncValueLike.data(T data) : this(value: data);
  const AsyncValueLike.error(Object error) : this(error: error);
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
                    color:
                        isSelected ? Colors.white : AppColors.textSecondary,
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
