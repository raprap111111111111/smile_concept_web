// lib/data/models/inventory/treatment_consumable_model.dart

import 'inventory_item_model.dart';

/// One line of a treatment's recipe: which supply, and how much of it a single
/// performance of that treatment uses.
///
/// Hand-written like every other model here — the project does not run
/// build_runner.
class TreatmentConsumableModel {
  final int? id;
  final int? treatmentId;
  final int itemId;
  final int quantityPerUse;

  /// Listed for reference but skipped by automatic deduction.
  final bool isOptional;

  final String? notes;
  final InventoryItemModel? item;

  const TreatmentConsumableModel({
    this.id,
    this.treatmentId,
    required this.itemId,
    required this.quantityPerUse,
    this.isOptional = false,
    this.notes,
    this.item,
  });

  factory TreatmentConsumableModel.fromJson(Map<String, dynamic> json) {
    return TreatmentConsumableModel(
      id: _asIntOrNull(json['id']),
      treatmentId: _asIntOrNull(json['treatment_id']),
      itemId: _asInt(json['item_id']),
      quantityPerUse: _asInt(json['quantity_per_use']),
      isOptional: _asBool(json['is_optional']),
      notes: json['notes'] as String?,
      item: json['item'] == null
          ? null
          : InventoryItemModel.fromJson(
              Map<String, dynamic>.from(json['item'] as Map),
            ),
    );
  }

  /// Write shape for the sync endpoint. Deliberately omits `id` — the server
  /// matches lines on item_id, so the client never has to track row identity.
  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity_per_use': quantityPerUse,
        'is_optional': isOptional,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  TreatmentConsumableModel copyWith({
    int? quantityPerUse,
    bool? isOptional,
    String? notes,
    InventoryItemModel? item,
  }) {
    return TreatmentConsumableModel(
      id: id,
      treatmentId: treatmentId,
      itemId: itemId,
      quantityPerUse: quantityPerUse ?? this.quantityPerUse,
      isOptional: isOptional ?? this.isOptional,
      notes: notes ?? this.notes,
      item: item ?? this.item,
    );
  }

  /// e.g. "2 carpules". Formatting lives on the model, matching how money is
  /// handled across this codebase.
  String get amountLabel {
    final unit = item?.unitOfMeasure ?? 'unit';
    return quantityPerUse > 1 ? '$quantityPerUse ${unit}s' : '$quantityPerUse $unit';
  }

  String get displayName => item?.name ?? 'Item #$itemId';

  static int _asInt(dynamic value) => _asIntOrNull(value) ?? 0;

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TreatmentConsumableModel && other.itemId == itemId);

  @override
  int get hashCode => itemId.hashCode;
}
