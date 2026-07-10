// lib/data/models/doctor_schedule/doctor_option_model.dart

class DoctorOption {
  final int id;
  final String name;
  final String specialization;
  final String? licenseNumber;

  const DoctorOption({
    required this.id,
    required this.name,
    required this.specialization,
    this.licenseNumber,
  });

  /// ✅ Parses doctor from API — grabs name from nested user.name
  ///
  /// Expected API response:
  /// {
  ///   "id": 1,
  ///   "specialization": "Teeth",
  ///   "license_number": "112627",
  ///   "user": { "id": 2, "name": "DR. JUVILE ANN..." }
  /// }
  factory DoctorOption.fromJson(Map<String, dynamic> json) {
    // Try user.name first (matches your Doctor model relationship)
    final user = json['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String?;

    // Fallback to profile.name (from resource output)
    final profile = json['profile'] as Map<String, dynamic>?;
    final profileName = profile?['name'] as String?;

    return DoctorOption(
      id: json['id'] as int,
      name: userName ?? profileName ?? 'Unknown Doctor',
      specialization:
          (json['specialization'] ?? json['specialty'] ?? '') as String,
      licenseNumber: json['license_number'] as String?,
    );
  }

  /// Nice label for the dropdown
  String get displayLabel {
    if (specialization.isNotEmpty) return '$name — $specialization';
    return name;
  }
}