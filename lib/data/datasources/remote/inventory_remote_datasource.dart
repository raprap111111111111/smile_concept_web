// lib/data/datasources/remote/inventory_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../models/inventory/inventory_model.dart';

class InventoryRemoteDataSource {
  final Dio dio;
  InventoryRemoteDataSource({required this.dio});

  // ── GET paginated list ─────────────────────────────────────
  Future<Map<String, dynamic>> fetchInventories({
    int page = 1,
    int? branchId,
    int? itemId,
    bool? lowStockOnly,
    String? search,
  }) async {
    final response = await dio.get(
      '/inventories',
      queryParameters: {
        'page': page,
        if (branchId != null) 'branch_id': branchId,
        if (itemId != null) 'item_id': itemId,
        if (lowStockOnly == true) 'low_stock_only': 1,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ── GET single ─────────────────────────────────────────────
  Future<InventoryModel> fetchInventoryById(int id) async {
    final response = await dio.get('/inventories/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return InventoryModel.fromJson(data);
  }

  // ── POST create ────────────────────────────────────────────
  Future<InventoryModel> createInventory({
    required int branchId,
    required int itemId,
    required int quantity,
    String? expiryDate,
  }) async {
    try {
      final response = await dio.post(
        '/inventories',
        data: {
          'branch_id': branchId,
          'item_id':   itemId,
          'quantity':  quantity,
          if (expiryDate != null) 'expiry_date': expiryDate,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return InventoryModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Failed to create inventory',
      );
    }
  }

  // ── PUT update ─────────────────────────────────────────────
  Future<InventoryModel> updateInventory({
    required int id,
    int? branchId,
    int? itemId,
    int? quantity,
    String? expiryDate,
  }) async {
    try {
      final response = await dio.put(
        '/inventories/$id',
        data: {
          if (branchId != null) 'branch_id': branchId,
          if (itemId != null) 'item_id': itemId,
          if (quantity != null) 'quantity': quantity,
          if (expiryDate != null) 'expiry_date': expiryDate,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return InventoryModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Failed to update inventory',
      );
    }
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<void> deleteInventory(int id) async {
    try {
      await dio.delete('/inventories/$id');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Failed to delete inventory',
      );
    }
  }
}