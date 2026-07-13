// lib/data/models/treatment/treatment_model.dart

class TreatmentModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int estimatedDurationMinutes;
  final bool isActive;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  const TreatmentModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.estimatedDurationMinutes = 30,
    this.isActive = true,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id:   _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: _asDouble(json['price']),
      estimatedDurationMinutes:
          _asInt(json['estimated_duration_minutes']),
      isActive: _asBool(json['is_active'], fallback: true),
      deletedAt:  json['deleted_at']?.toString(),
      createdAt:  json['created_at']?.toString(),
      updatedAt:  json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':                          id,
        'name':                        name,
        'description':                 description,
        'price':                       price,
        'estimated_duration_minutes':  estimatedDurationMinutes,
        'is_active':                   isActive,
      };

  // ── Display helpers ────────────────────────────────────────
  String get formattedPrice => '₱${price.toStringAsFixed(2)}';

  String get durationLabel {
    if (estimatedDurationMinutes < 60) {
      return '$estimatedDurationMinutes min';
    }
    final hours   = estimatedDurationMinutes ~/ 60;
    final minutes = estimatedDurationMinutes % 60;
    return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
  }

  // ── Private parsers ────────────────────────────────────────
  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return fallback;
  }

  @override
  String toString() =>
      'TreatmentModel(id: $id, name: $name, price: $price)';
}