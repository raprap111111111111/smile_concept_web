// lib/data/models/inventory/inventory_model.dart

import 'inventory_item_model.dart';
import 'inventory_branch_model.dart';

class InventoryModel {
  final int id;
  final int branchId;
  final int itemId;
  final int quantity;
  final String? expiryDate;
  final bool isLowStock;
  final bool isExpired;
  final InventoryItemModel? item;
  final InventoryBranchModel? branch;
  final String? createdAt;
  final String? updatedAt;

  const InventoryModel({
    required this.id,
    required this.branchId,
    required this.itemId,
    required this.quantity,
    this.expiryDate,
    this.isLowStock = false,
    this.isExpired = false,
    this.item,
    this.branch,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id:         _asInt(json['id']),
      branchId:   _asInt(json['branch_id']),
      itemId:     _asInt(json['item_id']),
      quantity:   _asInt(json['quantity']),
      expiryDate: json['expiry_date']?.toString(),
      isLowStock: _asBool(json['is_low_stock']),
      isExpired:  _asBool(json['is_expired']),
      item: json['item'] != null
          ? InventoryItemModel.fromJson(
              json['item'] as Map<String, dynamic>)
          : null,
      branch: json['branch'] != null
          ? InventoryBranchModel.fromJson(
              json['branch'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'branch_id': branchId,
        'item_id': itemId,
        'quantity': quantity,
        'expiry_date': expiryDate,
      };

  // ── Display helpers ────────────────────────────────────────
  String get quantityLabel {
    final unit = item?.unitOfMeasure ?? 'unit';
    return '$quantity $unit${quantity > 1 ? 's' : ''}';
  }

  String get stockStatusLabel {
    if (isExpired) return 'Expired';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  // ── Private parsers ────────────────────────────────────────
  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return fallback;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'InventoryModel(id: $id, item: ${item?.name}, qty: $quantity)';
}