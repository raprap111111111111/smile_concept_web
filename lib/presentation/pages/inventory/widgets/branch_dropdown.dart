// lib/presentation/pages/inventory/widgets/branch_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/inventory/inventory_form_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'dropdown_states.dart';

class BranchDropdown extends ConsumerWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const BranchDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesSimpleListProvider);

    return branchesAsync.when(
      loading: () =>
          const DropdownSkeleton(label: 'Loading branches...'),
      error: (e, _) => DropdownError(
        message: 'Failed to load branches',
        onRetry: () => ref.invalidate(branchesSimpleListProvider),
      ),
      data: (branches) {
        if (branches.isEmpty) {
          return const DropdownError(
            message: 'No branches available. Please add a branch first.',
          );
        }

        return DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          style: AppTextStyles.bodyMedium,
          decoration: const InputDecoration(
            labelText: 'Branch *',
            prefixIcon: Icon(Icons.location_on_outlined),
            helperText: 'Which branch stores this item',
          ),
          hint: Text(
            'Select a branch',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          items: branches
              .map(
                (br) => DropdownMenuItem<int>(
                  value: br.id,
                  child: Text(
                    br.displayLabel,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select a branch' : null,
        );
      },
    );
  }
}