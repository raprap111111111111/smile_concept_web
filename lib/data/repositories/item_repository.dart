// lib/data/repositories/item_repository.dart

import '../datasources/remote/item_remote_datasource.dart';
import '../models/inventory/item_model.dart';

class ItemPaginatedResult {
  final List<ItemModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const ItemPaginatedResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class ItemRepository {
  final ItemRemoteDataSource remoteDataSource;

  ItemPaginatedResult? _cachedFirstPage;
  DateTime? _lastFetched;

  ItemRepository({required this.remoteDataSource});

  Future<ItemPaginatedResult> getItems({
    int page = 1,
    String? search,
    String? category,
    bool forceRefresh = false,
  }) async {
    final isCacheable = page == 1 &&
        (search == null || search.isEmpty) &&
        (category == null || category.isEmpty);

    final isCacheValid = _lastFetched != null &&
        DateTime.now().difference(_lastFetched!).inMinutes < 5;

    if (isCacheable &&
        !forceRefresh &&
        isCacheValid &&
        _cachedFirstPage != null) {
      return _cachedFirstPage!;
    }

    final response = await remoteDataSource.fetchItems(
      page: page,
      search: search,
      category: category,
    );

    final data = response['data'] as Map<String, dynamic>;
    // ✅ Uses 'records' to match your API
    final list = (data['records'] as List<dynamic>? ?? [])
        .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final result = ItemPaginatedResult(
      items:       list,
      currentPage: _asInt(data['current_page']),
      lastPage:    _asInt(data['last_page']),
      total:       _asInt(data['total']),
    );

    if (isCacheable) {
      _cachedFirstPage = result;
      _lastFetched = DateTime.now();
    }

    return result;
  }

  Future<ItemModel> createItem({
    required String name,
    required String sku,
    required String category,
    required String unitOfMeasure,
    int minimumThreshold = 10,
  }) async {
    final result = await remoteDataSource.createItem(
      name: name,
      sku: sku,
      category: category,
      unitOfMeasure: unitOfMeasure,
      minimumThreshold: minimumThreshold,
    );
    clearCache();
    return result;
  }

  Future<ItemModel> updateItem({
    required int id,
    String? name,
    String? sku,
    String? category,
    String? unitOfMeasure,
    int? minimumThreshold,
  }) async {
    final result = await remoteDataSource.updateItem(
      id: id,
      name: name,
      sku: sku,
      category: category,
      unitOfMeasure: unitOfMeasure,
      minimumThreshold: minimumThreshold,
    );
    clearCache();
    return result;
  }

  Future<void> deleteItem(int id) async {
    await remoteDataSource.deleteItem(id);
    clearCache();
  }

  void clearCache() {
    _cachedFirstPage = null;
    _lastFetched = null;
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}