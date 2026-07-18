// lib/data/repositories/inventory_repository.dart

import '../datasources/remote/inventory_remote_datasource.dart';
import '../models/inventory/inventory_model.dart';

class InventoryPaginatedResult {
  final List<InventoryModel> inventories;
  final int currentPage;
  final int lastPage;
  final int total;

  const InventoryPaginatedResult({
    required this.inventories,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  // Simple in-memory cache
  InventoryPaginatedResult? _cachedFirstPage;
  DateTime? _lastFetched;

  InventoryRepository({required this.remoteDataSource});

  // ── Paginated list ─────────────────────────────────────────
  Future<InventoryPaginatedResult> getInventories({
    int page = 1,
    int? branchId,
    int? itemId,
    bool? lowStockOnly,
    String? search,
    bool forceRefresh = false,
  }) async {
    final isCacheable = page == 1 &&
        branchId == null &&
        itemId == null &&
        lowStockOnly == null &&
        (search == null || search.isEmpty);

    final isCacheValid = _lastFetched != null &&
        DateTime.now().difference(_lastFetched!).inMinutes < 5;

    if (isCacheable &&
        !forceRefresh &&
        isCacheValid &&
        _cachedFirstPage != null) {
      return _cachedFirstPage!;
    }

    final response = await remoteDataSource.fetchInventories(
      page: page,
      branchId: branchId,
      itemId: itemId,
      lowStockOnly: lowStockOnly,
      search: search,
    );

    final data = response['data'] as Map<String, dynamic>;
    final list = (data['records'] as List<dynamic>? ?? [])
        .map((e) => InventoryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final result = InventoryPaginatedResult(
      inventories: list,
      currentPage: _asInt(data['current_page']),
      lastPage: _asInt(data['last_page']),
      total: _asInt(data['total']),
    );

    if (isCacheable) {
      _cachedFirstPage = result;
      _lastFetched = DateTime.now();
    }

    return result;
  }

  // ── Single ─────────────────────────────────────────────────
  Future<InventoryModel> getInventoryById(int id) =>
      remoteDataSource.fetchInventoryById(id);

  // ── Create ─────────────────────────────────────────────────
  Future<InventoryModel> createInventory({
    required int branchId,
    required int itemId,
    required int quantity,
    String? expiryDate,
  }) async {
    final result = await remoteDataSource.createInventory(
      branchId: branchId,
      itemId: itemId,
      quantity: quantity,
      expiryDate: expiryDate,
    );
    clearCache();
    return result;
  }

  // ── Update ─────────────────────────────────────────────────
  Future<InventoryModel> updateInventory({
    required int id,
    int? branchId,
    int? itemId,
    int? quantity,
    String? expiryDate,
  }) async {
    final result = await remoteDataSource.updateInventory(
      id: id,
      branchId: branchId,
      itemId: itemId,
      quantity: quantity,
      expiryDate: expiryDate,
    );
    clearCache();
    return result;
  }

  // ── Delete ─────────────────────────────────────────────────
  Future<void> deleteInventory(int id) async {
    await remoteDataSource.deleteInventory(id);
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
