// lib/presentation/providers/inventory/item_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/remote/item_remote_datasource.dart';
import '../../../data/models/inventory/item_model.dart';
import '../../../data/repositories/item_repository.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

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

  /// The active search term.
  ///
  /// Held in state so paging can carry it — loadMore() used to fetch page 2
  /// with no term at all, which silently appended unfiltered rows underneath a
  /// filtered page 1.
  final String? searchQuery;

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
    this.searchQuery,
  });

  bool get hasListError   => listError != null;
  bool get hasDetailError => detailError != null;
  bool get hasSubmitError => submitError != null;
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
    String? searchQuery,
    bool clearListError   = false,
    bool clearDetailError = false,
    bool clearSubmitError = false,
    bool clearSelected    = false,
    bool clearSearchQuery = false,
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
      searchQuery:     clearSearchQuery ? null : searchQuery ?? this.searchQuery,
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
      searchQuery: search,
      // An empty term means "show everything", not "keep the old term".
      clearSearchQuery: search != null && search.isEmpty,
    );

    try {
      final result = await _repository.getItems(
        page: 1,
        search: search ?? state.searchQuery,
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
        listError: describeError(e),
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
        // Without this, page 2 came back unfiltered and was appended
        // underneath a filtered page 1.
        search: state.searchQuery,
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
        listError: describeError(e),
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
        detailError: describeError(e),
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
        submitError: describeError(e),
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
        submitError: describeError(e),
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
        listError: describeError(e),
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