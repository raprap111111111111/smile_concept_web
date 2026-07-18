// lib/presentation/providers/inventory/inventory_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/remote/inventory_remote_datasource.dart';
import '../../../data/models/inventory/inventory_model.dart';
import '../../../data/repositories/inventory_repository.dart';

// ── Data source provider ───────────────────────────────────────
final inventoryRemoteDataSourceProvider =
    Provider<InventoryRemoteDataSource>((ref) {
  return InventoryRemoteDataSource(dio: ref.read(dioProvider));
});

// ── Repository provider ────────────────────────────────────────
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(
    remoteDataSource: ref.read(inventoryRemoteDataSourceProvider),
  );
});

// ── State ──────────────────────────────────────────────────────
class InventoryState {
  final List<InventoryModel> inventories;
  final InventoryModel? selected;
  final bool isListLoading;
  final bool isDetailLoading;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? listError;
  final String? detailError;
  final String? submitError;
  final int currentPage;
  final int lastPage;
  final int total;
  final int? branchFilter;
  final bool lowStockOnly;
  final String? searchQuery;

  const InventoryState({
    this.inventories = const [],
    this.selected,
    this.isListLoading = false,
    this.isDetailLoading = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.listError,
    this.detailError,
    this.submitError,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.branchFilter,
    this.lowStockOnly = false,
    this.searchQuery,
  });

  bool get hasListError => listError != null;
  bool get hasDetailError => detailError != null;
  bool get hasSubmitError => submitError != null;
  bool get hasMore => currentPage < lastPage;
  bool get isEmpty =>
      !isListLoading && inventories.isEmpty && listError == null;

  int get lowStockCount =>
      inventories.where((i) => i.isLowStock).length;

  int get expiredCount =>
      inventories.where((i) => i.isExpired).length;

  InventoryState copyWith({
    List<InventoryModel>? inventories,
    InventoryModel? selected,
    bool? isListLoading,
    bool? isDetailLoading,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? listError,
    String? detailError,
    String? submitError,
    int? currentPage,
    int? lastPage,
    int? total,
    int? branchFilter,
    bool? lowStockOnly,
    String? searchQuery,
    bool clearSelected = false,
    bool clearListError = false,
    bool clearDetailError = false,
    bool clearSubmitError = false,
    bool clearBranchFilter = false,
    bool clearSearchQuery = false,
  }) {
    return InventoryState(
      inventories:     inventories ?? this.inventories,
      selected:        clearSelected ? null : selected ?? this.selected,
      isListLoading:   isListLoading ?? this.isListLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isLoadingMore:   isLoadingMore ?? this.isLoadingMore,
      isSubmitting:    isSubmitting ?? this.isSubmitting,
      listError:       clearListError ? null : listError ?? this.listError,
      detailError:     clearDetailError ? null : detailError ?? this.detailError,
      submitError:     clearSubmitError ? null : submitError ?? this.submitError,
      currentPage:     currentPage ?? this.currentPage,
      lastPage:        lastPage ?? this.lastPage,
      total:           total ?? this.total,
      branchFilter:    clearBranchFilter ? null : branchFilter ?? this.branchFilter,
      lowStockOnly:    lowStockOnly ?? this.lowStockOnly,
      searchQuery:     clearSearchQuery ? null : searchQuery ?? this.searchQuery,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────
class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryRepository _repository;

  InventoryNotifier(this._repository) : super(const InventoryState());

  // ── Load list ──────────────────────────────────────────────
  Future<void> loadInventories({
    int? branchId,
    bool? lowStockOnly,
    String? search,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(
      isListLoading: true,
      clearListError: true,
      currentPage: 1,
      branchFilter: branchId ?? state.branchFilter,
      lowStockOnly: lowStockOnly ?? state.lowStockOnly,
      searchQuery: search ?? state.searchQuery,
    );

    try {
      final result = await _repository.getInventories(
        page: 1,
        branchId: branchId ?? state.branchFilter,
        lowStockOnly: lowStockOnly ?? state.lowStockOnly,
        search: search ?? state.searchQuery,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        inventories:   result.inventories,
        currentPage:   result.currentPage,
        lastPage:      result.lastPage,
        total:         result.total,
        isListLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isListLoading: false,
        listError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Load more ──────────────────────────────────────────────
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getInventories(
        page: state.currentPage + 1,
        branchId: state.branchFilter,
        lowStockOnly: state.lowStockOnly,
        search: state.searchQuery,
      );

      state = state.copyWith(
        inventories: [...state.inventories, ...result.inventories],
        currentPage: result.currentPage,
        lastPage:    result.lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        listError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Load single ────────────────────────────────────────────
  Future<void> loadById(int id) async {
    state = state.copyWith(
      isDetailLoading: true,
      clearDetailError: true,
      clearSelected: true,
    );

    try {
      final result = await _repository.getInventoryById(id);
      state = state.copyWith(
        selected: result,
        isDetailLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isDetailLoading: false,
        detailError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Create ─────────────────────────────────────────────────
  Future<void> createInventory({
    required int branchId,
    required int itemId,
    required int quantity,
    String? expiryDate,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
    );

    try {
      await _repository.createInventory(
        branchId: branchId,
        itemId: itemId,
        quantity: quantity,
        expiryDate: expiryDate,
      );
      state = state.copyWith(isSubmitting: false);
      await loadInventories(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // ── Update ─────────────────────────────────────────────────
  Future<void> updateInventory({
    required int id,
    int? branchId,
    int? itemId,
    int? quantity,
    String? expiryDate,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
    );

    try {
      final updated = await _repository.updateInventory(
        id: id,
        branchId: branchId,
        itemId: itemId,
        quantity: quantity,
        expiryDate: expiryDate,
      );

      // Replace item in list immediately
      final updatedList = state.inventories.map((i) {
        return i.id == id ? updated : i;
      }).toList();

      state = state.copyWith(
        isSubmitting: false,
        inventories: updatedList,
        selected: updated,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // ── Delete ─────────────────────────────────────────────────
  Future<bool> deleteInventory(int id) async {
    try {
      await _repository.deleteInventory(id);
      state = state.copyWith(
        inventories: state.inventories.where((i) => i.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        listError: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Filter helpers ─────────────────────────────────────────
  Future<void> filterByBranch(int? branchId) async {
    state = state.copyWith(
      branchFilter: branchId,
      clearBranchFilter: branchId == null,
    );
    await loadInventories(forceRefresh: true);
  }

  Future<void> toggleLowStockFilter() async {
    state = state.copyWith(lowStockOnly: !state.lowStockOnly);
    await loadInventories(forceRefresh: true);
  }

  Future<void> search(String query) async {
    state = state.copyWith(
      searchQuery: query,
      clearSearchQuery: query.isEmpty,
    );
    await loadInventories(forceRefresh: true);
  }

  Future<void> refresh() => loadInventories(forceRefresh: true);
}

// ── Final provider ─────────────────────────────────────────────
final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier(ref.read(inventoryRepositoryProvider));
});