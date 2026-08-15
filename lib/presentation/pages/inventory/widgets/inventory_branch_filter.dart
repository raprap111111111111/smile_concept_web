// lib/presentation/pages/inventory/widgets/inventory_branch_filter.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/inventory/inventory_form_providers.dart';
import '../../../widgets/shared/branch_filter_chips.dart';

/// Branch pills for the inventory list.
///
/// `InventoryNotifier` has had `filterByBranch` and `state.branchFilter` since
/// it was written, but nothing ever called them — on a system whose whole point
/// is per-branch stock, there was no way to ask "what is on the shelf at
/// Satellite?".
///
/// The server scopes stock to the branches a user works at, and the provider
/// behind this asks `/branches?mine=1`, so the pills and the data agree: every
/// branch offered here is one whose stock this user can actually read.
class InventoryBranchFilter extends ConsumerWidget {
  final int? selectedBranchId;
  final ValueChanged<int?> onChanged;

  const InventoryBranchFilter({
    super.key,
    required this.selectedBranchId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesSimpleListProvider);

    return BranchFilterChips(
      branches: AsyncValueLike(
        value: branchesAsync.valueOrNull
            ?.map((b) => BranchFilterOption(id: b.id, name: b.name))
            .toList(),
        error: branchesAsync.error,
        isLoading: branchesAsync.isLoading,
      ),
      selectedBranchId: selectedBranchId,
      onChanged: onChanged,
      onRetry: () => ref.invalidate(branchesSimpleListProvider),
    );
  }
}
