// lib/data/models/patient/patient_model.dart

class PatientModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;

  // Demographic & Address fields
  final String? birthdate;
  final String? occupation;
  final String? address;
  final String? city;
  final String? province;
  final String? insuranceProvider;

  // Medical fields
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
    this.birthdate,
    this.occupation,
    this.address,
    this.city,
    this.province,
    this.insuranceProvider,
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

  // ✅ Getters required by patient detail & list pages
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

    final profile = (json['patient_profile'] is Map)
        ? json['patient_profile'] as Map<String, dynamic>
        : json;

    return PatientModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ??
          (userMap?['id'] as num?)?.toInt() ??
          0,
      name: userMap?['name']?.toString() ??
          json['name']?.toString() ??
          'Unknown',
      email: userMap?['email']?.toString() ??
          json['email']?.toString() ??
          '',
      phone: userMap?['phone']?.toString() ?? json['phone']?.toString(),
      profilePhotoUrl: userMap?['profile_photo_url']?.toString(),

      // Demographic & Profile extraction
      birthdate: profile['date_of_birth']?.toString(),
      occupation: profile['occupation']?.toString(),
      address: profile['address']?.toString(),
      city: profile['city']?.toString(),
      province: profile['province']?.toString(),
      insuranceProvider: profile['insurance_provider']?.toString(),

      allergies: profile['allergies']?.toString(),
      medicalHistory: profile['medical_history']?.toString(),
      bloodType: profile['blood_type']?.toString(),
      emergencyContactName: profile['emergency_contact_name']?.toString(),
      emergencyContactPhone: profile['emergency_contact_phone']?.toString(),
      requiresEpinephrineFreeAnesthesia:
          asBool(profile['requires_epinephrine_free_anesthesia']),
      hasCardiacConditions: asBool(profile['has_cardiac_conditions']),
      isPregnant: asBool(profile['is_pregnant']),
      hasBleedingDisorders: asBool(profile['has_bleeding_disorders']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

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