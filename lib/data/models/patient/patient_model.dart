// lib/data/models/patient/patient_model.dart

class PatientModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;

  final String? allergies;
  final String? medicalHistory;
  final String? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool requiresEpinephrineFreeAnesthesia;
  final bool hasCardiacConditions;
  final bool isPregnant;
  final bool hasBleedingDisorders;

  final String? createdAt;
  final String? updatedAt;

  const PatientModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    this.allergies,
    this.medicalHistory,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.requiresEpinephrineFreeAnesthesia = false,
    this.hasCardiacConditions = false,
    this.isPregnant = false,
    this.hasBleedingDisorders = false,
    this.createdAt,
    this.updatedAt,
  });

  int? get branchId => null;

  PatientProfileModel get patientProfile => PatientProfileModel(
        id: id,
        allergies: allergies,
        medicalHistory: medicalHistory,
        bloodType: bloodType,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        requiresEpinephrineFreeAnesthesia: requiresEpinephrineFreeAnesthesia,
        hasCardiacConditions: hasCardiacConditions,
        isPregnant: isPregnant,
        hasBleedingDisorders: hasBleedingDisorders,
      );

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    bool asBool(dynamic v) => v == 1 || v == true || v == '1' || v == 'true';

    Map<String, dynamic>? userMap;
    final rawPatient = json['patient'] ?? json['user'];

    if (rawPatient is Map) {
      userMap = <String, dynamic>{};
      rawPatient.forEach((key, value) {
        userMap![key.toString()] = value;
      });
    }

    return PatientModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      name: userMap?['name']?.toString() ?? 'Unknown',
      email: userMap?['email']?.toString() ?? '',
      phone: userMap?['phone']?.toString(),
      profilePhotoUrl: userMap?['profile_photo_url']?.toString(),
      allergies: json['allergies']?.toString(),
      medicalHistory: json['medical_history']?.toString(),
      bloodType: json['blood_type']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactPhone: json['emergency_contact_phone']?.toString(),
      requiresEpinephrineFreeAnesthesia:
          asBool(json['requires_epinephrine_free_anesthesia']),
      hasCardiacConditions: asBool(json['has_cardiac_conditions']),
      isPregnant: asBool(json['is_pregnant']),
      hasBleedingDisorders: asBool(json['has_bleeding_disorders']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  /// Used for UPDATE only (no user fields)
  Map<String, dynamic> toJson() => {
        'allergies': allergies,
        'medical_history': medicalHistory,
        'blood_type': bloodType,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'requires_epinephrine_free_anesthesia':
            requiresEpinephrineFreeAnesthesia,
        'has_cardiac_conditions': hasCardiacConditions,
        'is_pregnant': isPregnant,
        'has_bleeding_disorders': hasBleedingDisorders,
      };
}

class PatientProfileModel {
  final int id;
  final String? allergies;
  final String? medicalHistory;
  final String? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool requiresEpinephrineFreeAnesthesia;
  final bool hasCardiacConditions;
  final bool isPregnant;
  final bool hasBleedingDisorders;

  const PatientProfileModel({
    required this.id,
    this.allergies,
    this.medicalHistory,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.requiresEpinephrineFreeAnesthesia = false,
    this.hasCardiacConditions = false,
    this.isPregnant = false,
    this.hasBleedingDisorders = false,
  });
}