// lib/data/models/patient_summary_model.dart

/// Lightweight model for patient selection dropdowns.
/// Matches the Laravel response from:
///   GET /api/v1/patient-attachments/patients
///   GET /api/v1/users
class PatientSummary {
  final int id;
  final String name;
  final String email;
  final String? profilePhoto;
  final int attachmentCount;
  final int xrayCount;
  final int pendingScans;

  const PatientSummary({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    this.attachmentCount = 0,
    this.xrayCount = 0,
    this.pendingScans = 0,
  });

  /// Parse from the /patient-attachments/patients endpoint
  /// Response shape: { id, name, email, profile_photo, attachment_count, xray_count, pending_scans }
  factory PatientSummary.fromJson(Map<String, dynamic> json) {
    return PatientSummary(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString(),
      attachmentCount: _parseInt(json['attachment_count']) ?? 0,
      xrayCount: _parseInt(json['xray_count']) ?? 0,
      pendingScans: _parseInt(json['pending_scans']) ?? 0,
    );
  }

  /// Parse from the /users endpoint (no attachment counts)
  factory PatientSummary.fromUserJson(Map<String, dynamic> json) {
    return PatientSummary(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Display initials for avatar
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}