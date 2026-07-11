// Simple model just for dropdowns (no need for full doctor model)
class DoctorSimpleModel {
  final int id;
  final String name;
  final String? specialization;

  const DoctorSimpleModel({
    required this.id,
    required this.name,
    this.specialization,
  });

  factory DoctorSimpleModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return DoctorSimpleModel(
      id: json['id'] as int,
      name: user?['name'] as String? ?? 'Doctor #${json['id']}',
      specialization: json['specialization'] as String?,
    );
  }

  String get displayLabel {
    if (specialization != null && specialization!.trim().isNotEmpty) {
      return 'Dr. $name — $specialization';
    }
    return 'Dr. $name';
  }
}