// lib/data/datasources/remote/item_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../models/inventory/item_model.dart';

class ItemRemoteDataSource {
  final Dio dio;
  ItemRemoteDataSource({required this.dio});

  // ── GET paginated ──────────────────────────────────────────
  Future<Map<String, dynamic>> fetchItems({
    int page = 1,
    String? search,
    String? category,
  }) async {
    final response = await dio.get(
      '/items',
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty)
          'category': category,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ── GET single ─────────────────────────────────────────────
  Future<ItemModel> fetchItemById(int id) async {
    final response = await dio.get('/items/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return ItemModel.fromJson(data);
  }

  // ── POST create ────────────────────────────────────────────
  Future<ItemModel> createItem({
    required String name,
    required String sku,
    required String category,
    required String unitOfMeasure,
    int minimumThreshold = 10,
  }) async {
    try {
      final response = await dio.post(
        '/items',
        data: {
          'name': name,
          'sku': sku,
          'category': category,
          'unit_of_measure': unitOfMeasure,
          'minimum_threshold': minimumThreshold,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return ItemModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to create item',
      );
    }
  }

  // ── PUT update ─────────────────────────────────────────────
  Future<ItemModel> updateItem({
    required int id,
    String? name,
    String? sku,
    String? category,
    String? unitOfMeasure,
    int? minimumThreshold,
  }) async {
    try {
      final response = await dio.put(
        '/items/$id',
        data: {
          if (name != null) 'name': name,
          if (sku != null) 'sku': sku,
          if (category != null) 'category': category,
          if (unitOfMeasure != null) 'unit_of_measure': unitOfMeasure,
          if (minimumThreshold != null)
            'minimum_threshold': minimumThreshold,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return ItemModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to update item',
      );
    }
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<void> deleteItem(int id) async {
    try {
      await dio.delete('/items/$id');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to delete item',
      );
    }
  }
}