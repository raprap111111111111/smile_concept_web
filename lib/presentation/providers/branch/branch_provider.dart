import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/branch/branch_model.dart';
import '../../../data/repositories/branch_repository.dart';

class BranchFilter {
  final String search;
  final bool? isActive;

  const BranchFilter({
    this.search = '',
    this.isActive,
  });

  BranchFilter copyWith({
    String? search,
    bool? isActive,
    bool clearActive = false,
  }) {
    return BranchFilter(
      search: search ?? this.search,
      isActive: clearActive ? null : isActive ?? this.isActive,
    );
  }
}

final branchFilterProvider = StateProvider<BranchFilter>((ref) {
  return const BranchFilter();
});

final branchesProvider = FutureProvider<List<BranchModel>>((ref) async {
  final filter = ref.watch(branchFilterProvider);
  final repository = ref.watch(branchRepositoryProvider);

  return repository.getBranches(
    search: filter.search,
    isActive: filter.isActive,
  );
});