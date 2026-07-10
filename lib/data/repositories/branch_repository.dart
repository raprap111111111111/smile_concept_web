// lib/data/repositories/branch_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/local/branch_local_datasource.dart';
import '../datasources/remote/branch_remote_datasource.dart';
import '../models/branch/branch_model.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository(
    remote: ref.watch(branchRemoteDataSourceProvider),
    local: ref.watch(branchLocalDataSourceProvider),
  );
});

class BranchRepository {
  final BranchRemoteDataSource _remote;
  final BranchLocalDataSource _local;

  BranchRepository({
    required BranchRemoteDataSource remote,
    required BranchLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  Future<List<BranchModel>> getBranches({
    String? search,
    bool? isActive,
  }) async {
    try {
      final branches = await _remote.getBranches(
        search: search,
        isActive: isActive,
      );

      await _local.cacheBranches(branches);

      return branches;
    } catch (e) {
      final cached = await _local.getCachedBranches();

      if (cached.isNotEmpty) {
        return _filterCached(
          cached,
          search: search,
          isActive: isActive,
        );
      }

      rethrow;
    }
  }

  Future<BranchModel> createBranch(Map<String, dynamic> data) async {
    final branch = await _remote.createBranch(data);
    await _local.cacheBranch(branch);
    return branch;
  }

  Future<BranchModel> updateBranch(
    int id,
    Map<String, dynamic> data,
  ) async {
    final branch = await _remote.updateBranch(id, data);
    await _local.cacheBranch(branch);
    return branch;
  }

  Future<void> deleteBranch(int id) async {
    await _remote.deleteBranch(id);
    await _local.deleteBranch(id);
  }

  List<BranchModel> _filterCached(
    List<BranchModel> branches, {
    String? search,
    bool? isActive,
  }) {
    final query = search?.trim().toLowerCase() ?? '';

    return branches.where((branch) {
      final matchesSearch = query.isEmpty ||
          branch.name.toLowerCase().contains(query) ||
          (branch.branchCode ?? '').toLowerCase().contains(query) ||
          (branch.city ?? '').toLowerCase().contains(query) ||
          (branch.province ?? '').toLowerCase().contains(query);

      final matchesActive = isActive == null || branch.isActive == isActive;

      return matchesSearch && matchesActive;
    }).toList();
  }
}