// lib/presentation/pages/doctor_schedules/widgets/branch_filter_row.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/doctor_schedule/schedule_form_providers.dart';
import '../../../widgets/shared/branch_filter_chips.dart';

/// Branch pills for the schedules page, mirroring [DayFilterRow] so the two
/// filters read as one control strip.
///
/// The strip itself lives in [BranchFilterChips] — the inventory page needs the
/// same control but sources its branches from a different provider, so this is
/// just the wiring for this page.
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
      onRetry: () => ref.invalidate(branchesListProvider),
    );
  }
}
