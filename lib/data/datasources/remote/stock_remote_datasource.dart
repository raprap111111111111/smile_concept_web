// lib/data/datasources/remote/stock_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../core/errors/error_message.dart';
import '../../models/inventory/inventory_batch_model.dart';
import '../../models/inventory/inventory_model.dart';
import '../../models/inventory/stock_movement_model.dart';

/// Outcome of one stock write.
///
/// Carries the refreshed summary row so the caller can patch its list in place
/// rather than refetching, and the shortfall so the UI can say plainly that
/// stock ran out — which is a warning, never a failure.
class StockActionResult {
  final InventoryModel? inventory;
  final List<StockMovementModel> movements;
  final int shortfall;
  final int balanceAfter;

  const StockActionResult({
    this.inventory,
    this.movements = const [],
    this.shortfall = 0,
    this.balanceAfter = 0,
  });

  bool get hasShortfall => shortfall > 0;

  factory StockActionResult.fromJson(Map<String, dynamic> json) {
    return StockActionResult(
      inventory: json['inventory'] == null
          ? null
          : InventoryModel.fromJson(
              Map<String, dynamic>.from(json['inventory'] as Map),
            ),
      movements: (json['movements'] as List<dynamic>? ?? [])
          .map((e) => StockMovementModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      shortfall: (json['shortfall'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toInt() ?? 0,
    );
  }
}

class StockRemoteDataSource {
  final Dio _dio;

  const StockRemoteDataSource({required Dio dio}) : _dio = dio;

  // ── Writes ────────────────────────────────────────

  Future<StockActionResult> stockIn({
    required int branchId,
    required int itemId,
    required int quantity,
    String? lotNumber,
    String? expiryDate,
    String? receivedAt,
    String? reason,
    String? notes,
  }) {
    return _write('/inventories/stock-in', {
      'branch_id': branchId,
      'item_id': itemId,
      'quantity': quantity,
      if (lotNumber != null && lotNumber.isNotEmpty) 'lot_number': lotNumber,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (receivedAt != null) 'received_at': receivedAt,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    }, 'Could not record the delivery.');
  }

  Future<StockActionResult> recordUsage({
    required int branchId,
    required int itemId,
    required int quantity,
    String? reason,
    String? notes,
  }) {
    return _write('/inventories/usage', {
      'branch_id': branchId,
      'item_id': itemId,
      'quantity': quantity,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    }, 'Could not record the usage.');
  }

  Future<StockActionResult> adjust({
    required int branchId,
    required int itemId,
    required int countedQuantity,
    required String reason,
    String? lotNumber,
    String? expiryDate,
    String? notes,
  }) {
    return _write('/inventories/adjust', {
      'branch_id': branchId,
      'item_id': itemId,
      'counted_quantity': countedQuantity,
      'reason': reason,
      if (lotNumber != null && lotNumber.isNotEmpty) 'lot_number': lotNumber,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    }, 'Could not adjust the stock.');
  }

  /// Transfer answers differently from the others: it returns a source and a
  /// destination rather than one summary row.
  Future<Map<String, dynamic>> transfer({
    required int fromBranchId,
    required int toBranchId,
    required int itemId,
    required int quantity,
    String? reason,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/inventories/transfer', data: {
        'from_branch_id': fromBranchId,
        'to_branch_id': toBranchId,
        'item_id': itemId,
        'quantity': quantity,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

      return Map<String, dynamic>.from(response.data['data'] as Map);
    } on DioException catch (e) {
      // 409 here means the source branch does not have the stock — unlike
      // usage, a transfer is refused rather than recorded short.
      throw Exception(describeError(e, fallback: 'Could not transfer the stock.'));
    }
  }

  Future<StockActionResult> _write(
    String path,
    Map<String, dynamic> body,
    String fallback,
  ) async {
    try {
      final response = await _dio.post(path, data: body);

      return StockActionResult.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );
    } on DioException catch (e) {
      throw Exception(describeError(e, fallback: fallback));
    }
  }

  // ── Reads ─────────────────────────────────────────

  Future<List<StockMovementModel>> fetchMovements({
    int? branchId,
    int? itemId,
    String? type,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get('/stock-movements', queryParameters: {
        'limit': limit,
        if (branchId != null) 'branch_id': branchId,
        if (itemId != null) 'item_id': itemId,
        if (type != null && type.isNotEmpty) 'type': type,
      });

      final records = response.data['data']['records'] as List<dynamic>? ?? [];

      return records
          .map((e) => StockMovementModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } on DioException catch (e) {
      throw Exception(describeError(e, fallback: 'Could not load the ledger.'));
    }
  }

  Future<List<InventoryBatchModel>> fetchBatches({
    int? branchId,
    int? itemId,
    bool openOnly = true,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get('/inventory-batches', queryParameters: {
        'limit': limit,
        'open_only': openOnly ? 1 : 0,
        if (branchId != null) 'branch_id': branchId,
        if (itemId != null) 'item_id': itemId,
      });

      final records = response.data['data']['records'] as List<dynamic>? ?? [];

      return records
          .map((e) => InventoryBatchModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } on DioException catch (e) {
      throw Exception(describeError(e, fallback: 'Could not load batches.'));
    }
  }
}
