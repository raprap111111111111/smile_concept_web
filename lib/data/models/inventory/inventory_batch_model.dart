// lib/data/models/inventory/inventory_batch_model.dart

import 'inventory_item_model.dart';

/// One delivery of one item into one branch — the unit consumption actually
/// draws from, earliest expiry first.
class InventoryBatchModel {
  final int id;
  final int branchId;
  final int itemId;
  final String? lotNumber;

  /// Null means non-perishable. Those are consumed last.
  final DateTime? expiryDate;

  final int quantityReceived;
  final int quantityRemaining;
  final DateTime? receivedAt;
  final bool isExpired;
  final String? notes;
  final InventoryItemModel? item;

  const InventoryBatchModel({
    required this.id,
    required this.branchId,
    required this.itemId,
    this.lotNumber,
    this.expiryDate,
    required this.quantityReceived,
    required this.quantityRemaining,
    this.receivedAt,
    this.isExpired = false,
    this.notes,
    this.item,
  });

  factory InventoryBatchModel.fromJson(Map<String, dynamic> json) {
    return InventoryBatchModel(
      id: _asInt(json['id']),
      branchId: _asInt(json['branch_id']),
      itemId: _asInt(json['item_id']),
      lotNumber: json['lot_number'] as String?,
      expiryDate: _asDate(json['expiry_date']),
      quantityReceived: _asInt(json['quantity_received']),
      quantityRemaining: _asInt(json['quantity_remaining']),
      receivedAt: _asDate(json['received_at']),
      isExpired: _asBool(json['is_expired']),
      notes: json['notes'] as String?,
      item: json['item'] == null
          ? null
          : InventoryItemModel.fromJson(
              Map<String, dynamic>.from(json['item'] as Map),
            ),
    );
  }

  String get lotLabel => (lotNumber == null || lotNumber!.isEmpty)
      ? 'No lot number'
      : 'Lot $lotNumber';

  /// Days until this batch expires. Negative once it has.
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;

    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);

    return expiryDate!.difference(midnight).inDays;
  }

  bool isExpiringWithin(int days) {
    final left = daysUntilExpiry;
    return left != null && left >= 0 && left <= days;
  }

  /// Plain-language expiry, so a reader never has to subtract dates in
  /// their head to know whether a lot is a problem.
  String get expiryLabel {
    if (expiryDate == null) return 'No expiry';

    final left = daysUntilExpiry!;

    if (left < 0) return 'Expired';
    if (left == 0) return 'Expires today';
    if (left == 1) return 'Expires tomorrow';
    if (left <= 60) return 'Expires in $left days';

    return 'Expires ${_formatDate(expiryDate!)}';
  }

  String get amountLabel {
    final unit = item?.unitOfMeasure ?? 'unit';
    return quantityRemaining == 1
        ? '$quantityRemaining $unit'
        : '$quantityRemaining ${unit}s';
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}
