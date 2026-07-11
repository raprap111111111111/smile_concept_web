// lib/data/models/profile/branch_summary_model.dart

class BranchSummaryModel {
  final int id;
  final String name;

  const BranchSummaryModel({
    required this.id,
    required this.name,
  });

  factory BranchSummaryModel.fromJson(Map<String, dynamic> json) {
    return BranchSummaryModel(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is double) return v.toInt();
  return 0;
}