// lib/presentation/providers/inventory/item_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/remote/item_remote_datasource.dart';
import '../../../data/models/inventory/item_model.dart';
import '../../../data/repositories/item_repository.dart';

// ── Data source ────────────────────────────────────────────────
final itemRemoteDataSourceProvider =
    Provider<ItemRemoteDataSource>((ref) {
  return ItemRemoteDataSource(dio: ref.read(dioProvider));
});

// ── Repository ─────────────────────────────────────────────────
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(
    remoteDataSource: ref.read(itemRemoteDataSourceProvider),
  );
});

// ── State ──────────────────────────────────────────────────────
class ItemState {
  final List<ItemModel> items;
  final ItemModel? selected;
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

  const ItemState({
    this.items = const [],
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
  });

  bool get hasListError   => listError != null;
  bool get hasDetailError => detailError != null;
  bool get hasMore        => currentPage < lastPage;
  bool get isEmpty        =>
      !isListLoading && items.isEmpty && listError == null;

  ItemState copyWith({
    List<ItemModel>? items,
    ItemModel? selected,
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
    bool clearListError   = false,
    bool clearDetailError = false,
    bool clearSubmitError = false,
    bool clearSelected    = false,
  }) {
    return ItemState(
      items:           items ?? this.items,
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
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────
class ItemNotifier extends StateNotifier<ItemState> {
  final ItemRepository _repository;

  ItemNotifier(this._repository) : super(const ItemState());

  // ── Load list ──────────────────────────────────────────────
  Future<void> loadItems({
    String? search,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(
      isListLoading: true,
      clearListError: true,
      currentPage: 1,
    );

    try {
      final result = await _repository.getItems(
        page: 1,
        search: search,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(
        items:         result.items,
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
      final result = await _repository.getItems(
        page: state.currentPage + 1,
      );
      state = state.copyWith(
        items:         [...state.items, ...result.items],
        currentPage:   result.currentPage,
        lastPage:      result.lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        listError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Load single by ID ──────────────────────────────────────  ← THIS IS THE MISSING METHOD
  Future<void> loadById(int id) async {
    state = state.copyWith(
      isDetailLoading: true,
      clearDetailError: true,
      clearSelected: true,
    );

    try {
      final item = await _repository.getItemById(id);
      state = state.copyWith(
        selected: item,
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
  Future<void> createItem({
    required String name,
    required String sku,
    required String category,
    required String unitOfMeasure,
    int minimumThreshold = 10,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
    );

    try {
      await _repository.createItem(
        name: name,
        sku: sku,
        category: category,
        unitOfMeasure: unitOfMeasure,
        minimumThreshold: minimumThreshold,
      );
      state = state.copyWith(isSubmitting: false);
      await loadItems(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // ── Update ─────────────────────────────────────────────────
  Future<void> updateItem({
    required int id,
    String? name,
    String? sku,
    String? category,
    String? unitOfMeasure,
    int? minimumThreshold,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
    );

    try {
      await _repository.updateItem(
        id: id,
        name: name,
        sku: sku,
        category: category,
        unitOfMeasure: unitOfMeasure,
        minimumThreshold: minimumThreshold,
      );
      state = state.copyWith(isSubmitting: false);
      await loadItems(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // ── Delete ─────────────────────────────────────────────────
  Future<bool> deleteItem(int id) async {
    try {
      await _repository.deleteItem(id);
      state = state.copyWith(
        items: state.items.where((i) => i.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        listError: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Refresh ────────────────────────────────────────────────
  Future<void> refresh() => loadItems(forceRefresh: true);
}

// ── Provider ───────────────────────────────────────────────────
final itemProvider =
    StateNotifierProvider<ItemNotifier, ItemState>((ref) {
  return ItemNotifier(ref.read(itemRepositoryProvider));
});