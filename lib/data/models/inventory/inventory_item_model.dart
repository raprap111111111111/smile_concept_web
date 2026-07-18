// lib/data/models/inventory/inventory_item_model.dart

class InventoryItemModel {
  final int id;
  final String name;
  final String? sku;
  final String? category;
  final String? unitOfMeasure;
  final int minimumThreshold;

  const InventoryItemModel({
    required this.id,
    required this.name,
    this.sku,
    this.category,
    this.unitOfMeasure,
    this.minimumThreshold = 10,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id:               _asInt(json['id']),
      name:             json['name']?.toString() ?? '',
      sku:              json['sku']?.toString(),
      category:         json['category']?.toString(),
      unitOfMeasure:    json['unit_of_measure']?.toString(),
      minimumThreshold: _asInt(json['minimum_threshold']),
    );
  }

  // ── Display helpers ────────────────────────────────────────
  String get displayLabel {
    if (sku != null && sku!.isNotEmpty) {
      return '$name • $sku';
    }
    return name;
  }

  String get categoryLabel => category ?? 'Uncategorized';

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}