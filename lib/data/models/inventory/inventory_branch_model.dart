// lib/data/models/inventory/inventory_branch_model.dart

class InventoryBranchModel {
  final int id;
  final String name;
  final String? branchCode;

  const InventoryBranchModel({
    required this.id,
    required this.name,
    this.branchCode,
  });

  factory InventoryBranchModel.fromJson(Map<String, dynamic> json) {
    return InventoryBranchModel(
      id:         _asInt(json['id']),
      name:       json['name']?.toString() ?? '',
      branchCode: json['branch_code']?.toString(),
    );
  }

  // ── Display helpers ────────────────────────────────────────
  String get displayLabel {
    if (branchCode != null && branchCode!.isNotEmpty) {
      return '$name ($branchCode)';
    }
    return name;
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}