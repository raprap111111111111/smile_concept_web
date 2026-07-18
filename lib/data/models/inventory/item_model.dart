// lib/data/models/inventory/item_model.dart

class ItemModel {
  final int id;
  final String name;
  final String sku;
  final String category;
  final String unitOfMeasure;
  final int minimumThreshold;
  final String? createdAt;
  final String? updatedAt;

  const ItemModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.unitOfMeasure,
    this.minimumThreshold = 10,
    this.createdAt,
    this.updatedAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id:               _asInt(json['id']),
      name:             json['name']?.toString() ?? '',
      sku:              json['sku']?.toString() ?? '',
      category:         json['category']?.toString() ?? '',
      unitOfMeasure:    json['unit_of_measure']?.toString() ?? '',
      minimumThreshold: _asInt(json['minimum_threshold']),
      createdAt:        json['created_at']?.toString(),
      updatedAt:        json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sku': sku,
        'category': category,
        'unit_of_measure': unitOfMeasure,
        'minimum_threshold': minimumThreshold,
      };

  // ── Display helpers ────────────────────────────────────────
  String get displayLabel => '$name • $sku';

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ItemModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}