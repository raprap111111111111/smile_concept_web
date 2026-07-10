import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/branch/branch_model.dart';

final branchLocalDataSourceProvider = Provider<BranchLocalDataSource>((ref) {
  return BranchLocalDataSource();
});

class BranchLocalDataSource {
  final Map<int, BranchModel> _cache = {};

  Future<void> cacheBranches(List<BranchModel> branches) async {
    _cache.clear();

    for (final branch in branches) {
      _cache[branch.id] = branch;
    }
  }

  Future<List<BranchModel>> getCachedBranches() async {
    return _cache.values.toList();
  }

  Future<void> cacheBranch(BranchModel branch) async {
    _cache[branch.id] = branch;
  }

  Future<BranchModel?> getCachedBranch(int id) async {
    return _cache[id];
  }

  Future<void> deleteBranch(int id) async {
    _cache.remove(id);
  }

  Future<void> clearCache() async {
    _cache.clear();
  }
}