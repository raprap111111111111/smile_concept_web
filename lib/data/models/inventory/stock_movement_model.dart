// lib/data/models/inventory/stock_movement_model.dart

import 'inventory_item_model.dart';

/// One line of the stock ledger.
///
/// Append-only server-side, so there is no write shape here — the client only
/// ever reads these.
class StockMovementModel {
  final int id;
  final int branchId;
  final int itemId;
  final int? inventoryBatchId;

  /// Raw enum value, e.g. `consumption`.
  final String type;

  /// Human label the server already resolved, e.g. "Used in treatment".
  final String typeLabel;

  /// Signed: negative removed stock.
  final int quantityDelta;

  /// Branch+item running total immediately after this row.
  final int balanceAfter;

  /// An outflow no batch could satisfy — stock ran short.
  final bool isShortfall;

  final String? reason;
  final String? notes;

  /// What caused it, e.g. `Appointment`.
  final String? referenceType;
  final int? referenceId;

  final InventoryItemModel? item;
  final String? branchName;
  final String? lotNumber;
  final String? performedByName;
  final DateTime? createdAt;

  const StockMovementModel({
    required this.id,
    required this.branchId,
    required this.itemId,
    this.inventoryBatchId,
    required this.type,
    required this.typeLabel,
    required this.quantityDelta,
    required this.balanceAfter,
    this.isShortfall = false,
    this.reason,
    this.notes,
    this.referenceType,
    this.referenceId,
    this.item,
    this.branchName,
    this.lotNumber,
    this.performedByName,
    this.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    final batch = json['batch'];
    final performer = json['performed_by'];

    return StockMovementModel(
      id: _asInt(json['id']),
      branchId: _asInt(json['branch_id']),
      itemId: _asInt(json['item_id']),
      inventoryBatchId: json['inventory_batch_id'] == null
          ? null
          : _asInt(json['inventory_batch_id']),
      type: json['type']?.toString() ?? '',
      typeLabel: json['type_label']?.toString() ?? '',
      quantityDelta: _asInt(json['quantity_delta']),
      balanceAfter: _asInt(json['balance_after']),
      isShortfall: _asBool(json['is_shortfall']),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId:
          json['reference_id'] == null ? null : _asInt(json['reference_id']),
      item: json['item'] == null
          ? null
          : InventoryItemModel.fromJson(
              Map<String, dynamic>.from(json['item'] as Map),
            ),
      branchName: json['branch'] is Map
          ? (json['branch'] as Map)['name'] as String?
          : null,
      lotNumber: batch is Map ? batch['lot_number'] as String? : null,
      performedByName:
          performer is Map ? performer['name'] as String? : null,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  bool get isInflow => quantityDelta > 0;

  /// Always signed, so a ledger column reads as a statement.
  String get deltaLabel =>
      quantityDelta > 0 ? '+$quantityDelta' : '$quantityDelta';

  /// Who or what to credit. Automatic deduction has no person behind it.
  String get actorLabel {
    if (performedByName != null && performedByName!.isNotEmpty) {
      return performedByName!;
    }
    if (referenceType != null) {
      return 'Automatic';
    }
    return 'System';
  }

  String get displayName => item?.name ?? 'Item #$itemId';

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}
