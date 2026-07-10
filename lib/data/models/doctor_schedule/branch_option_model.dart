// lib/data/models/doctor_schedule/branch_option_model.dart

class BranchOption {
  final int id;
  final String name;
  final String branchCode;

  const BranchOption({
    required this.id,
    required this.name,
    required this.branchCode,
  });

  factory BranchOption.fromJson(Map<String, dynamic> json) {
    return BranchOption(
      id: json['id'] as int,
      name: (json['name'] ?? 'Unknown') as String,
      branchCode: (json['branch_code'] ?? '') as String,
    );
  }

  String get displayLabel {
    if (branchCode.isNotEmpty) return '$name ($branchCode)';
    return name;
  }
}