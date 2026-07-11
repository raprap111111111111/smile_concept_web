// lib/data/models/profile/patient_profile_model.dart

class PatientProfileModel {
  final int id;
  final int userId;
  final String? allergies;
  final String? medicalHistory;
  final String? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool requiresEpinephrineFreeAnesthesia;
  final bool hasCardiacConditions;
  final bool isPregnant;
  final bool hasBleedingDisorders;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientProfileModel({
    required this.id,
    required this.userId,
    this.allergies,
    this.medicalHistory,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.requiresEpinephrineFreeAnesthesia = false,
    this.hasCardiacConditions = false,
    this.isPregnant = false,
    this.hasBleedingDisorders = false,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  // ── Business logic ────────────────────────────────────────────────────
  bool get hasMedicalAlerts =>
      hasCardiacConditions ||
      isPregnant ||
      hasBleedingDisorders ||
      requiresEpinephrineFreeAnesthesia;

  List<String> get activeAlerts => [
        if (hasCardiacConditions) 'Cardiac Condition',
        if (isPregnant) 'Pregnant',
        if (hasBleedingDisorders) 'Bleeding Disorder',
        if (requiresEpinephrineFreeAnesthesia) 'Epinephrine-Free Anesthesia',
      ];

  bool get isMedicallyComplete =>
      bloodType != null &&
      emergencyContactName != null &&
      emergencyContactPhone != null;

  bool get isDeleted => deletedAt != null;

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      allergies: json['allergies']?.toString(),
      medicalHistory: json['medical_history']?.toString(),
      bloodType: json['blood_type']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactPhone: json['emergency_contact_phone']?.toString(),
      requiresEpinephrineFreeAnesthesia:
          _asBool(json['requires_epinephrine_free_anesthesia']),
      hasCardiacConditions: _asBool(json['has_cardiac_conditions']),
      isPregnant: _asBool(json['is_pregnant']),
      hasBleedingDisorders: _asBool(json['has_bleeding_disorders']),
      deletedAt: _parseDate(json['deleted_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'allergies': allergies,
        'medical_history': medicalHistory,
        'blood_type': bloodType,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'requires_epinephrine_free_anesthesia': requiresEpinephrineFreeAnesthesia,
        'has_cardiac_conditions': hasCardiacConditions,
        'is_pregnant': isPregnant,
        'has_bleeding_disorders': hasBleedingDisorders,
        'deleted_at': deletedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Body for update requests (only editable fields)
  Map<String, dynamic> toUpdateJson() => {
        if (allergies != null) 'allergies': allergies,
        if (medicalHistory != null) 'medical_history': medicalHistory,
        if (bloodType != null) 'blood_type': bloodType,
        if (emergencyContactName != null)
          'emergency_contact_name': emergencyContactName,
        if (emergencyContactPhone != null)
          'emergency_contact_phone': emergencyContactPhone,
        'requires_epinephrine_free_anesthesia':
            requiresEpinephrineFreeAnesthesia,
        'has_cardiac_conditions': hasCardiacConditions,
        'is_pregnant': isPregnant,
        'has_bleeding_disorders': hasBleedingDisorders,
      };

  PatientProfileModel copyWith({
    String? allergies,
    String? medicalHistory,
    String? bloodType,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? requiresEpinephrineFreeAnesthesia,
    bool? hasCardiacConditions,
    bool? isPregnant,
    bool? hasBleedingDisorders,
  }) {
    return PatientProfileModel(
      id: id,
      userId: userId,
      allergies: allergies ?? this.allergies,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      bloodType: bloodType ?? this.bloodType,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      requiresEpinephrineFreeAnesthesia: requiresEpinephrineFreeAnesthesia ??
          this.requiresEpinephrineFreeAnesthesia,
      hasCardiacConditions: hasCardiacConditions ?? this.hasCardiacConditions,
      isPregnant: isPregnant ?? this.isPregnant,
      hasBleedingDisorders: hasBleedingDisorders ?? this.hasBleedingDisorders,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is double) return v.toInt();
  return 0;
}

bool _asBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}