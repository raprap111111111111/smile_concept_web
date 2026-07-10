// lib/data/models/patient/create_patient_payload.dart

/// Payload for creating a new Patient (User + PatientProfile).
/// Backend endpoint: POST /patient-profiles
class CreatePatientPayload {
  // ─── User account fields ──────────────────────────
  final String name;
  final String email;
  final String? phone;
  final String? password;

  // ─── Medical fields ───────────────────────────────
  final String? bloodType;
  final String? allergies;
  final String? medicalHistory;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool requiresEpinephrineFreeAnesthesia;
  final bool hasCardiacConditions;
  final bool isPregnant;
  final bool hasBleedingDisorders;

  const CreatePatientPayload({
    required this.name,
    required this.email,
    this.phone,
    this.password,
    this.bloodType,
    this.allergies,
    this.medicalHistory,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.requiresEpinephrineFreeAnesthesia = false,
    this.hasCardiacConditions = false,
    this.isPregnant = false,
    this.hasBleedingDisorders = false,
  });

  Map<String, dynamic> toJson() {
    // Strip nulls & empty strings so backend gets clean data
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (bloodType != null && bloodType!.isNotEmpty) 'blood_type': bloodType,
      if (allergies != null && allergies!.isNotEmpty) 'allergies': allergies,
      if (medicalHistory != null && medicalHistory!.isNotEmpty)
        'medical_history': medicalHistory,
      if (emergencyContactName != null && emergencyContactName!.isNotEmpty)
        'emergency_contact_name': emergencyContactName,
      if (emergencyContactPhone != null && emergencyContactPhone!.isNotEmpty)
        'emergency_contact_phone': emergencyContactPhone,
      'requires_epinephrine_free_anesthesia':
          requiresEpinephrineFreeAnesthesia,
      'has_cardiac_conditions': hasCardiacConditions,
      'is_pregnant': isPregnant,
      'has_bleeding_disorders': hasBleedingDisorders,
    };
    return map;
  }
}

/// Payload for updating an existing patient
class UpdatePatientPayload {
  final String? name;
  final String? email;
  final String? phone;

  final String? bloodType;
  final String? allergies;
  final String? medicalHistory;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool? requiresEpinephrineFreeAnesthesia;
  final bool? hasCardiacConditions;
  final bool? isPregnant;
  final bool? hasBleedingDisorders;

  const UpdatePatientPayload({
    this.name,
    this.email,
    this.phone,
    this.bloodType,
    this.allergies,
    this.medicalHistory,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.requiresEpinephrineFreeAnesthesia,
    this.hasCardiacConditions,
    this.isPregnant,
    this.hasBleedingDisorders,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (bloodType != null) map['blood_type'] = bloodType;
    if (allergies != null) map['allergies'] = allergies;
    if (medicalHistory != null) map['medical_history'] = medicalHistory;
    if (emergencyContactName != null) {
      map['emergency_contact_name'] = emergencyContactName;
    }
    if (emergencyContactPhone != null) {
      map['emergency_contact_phone'] = emergencyContactPhone;
    }
    if (requiresEpinephrineFreeAnesthesia != null) {
      map['requires_epinephrine_free_anesthesia'] =
          requiresEpinephrineFreeAnesthesia;
    }
    if (hasCardiacConditions != null) {
      map['has_cardiac_conditions'] = hasCardiacConditions;
    }
    if (isPregnant != null) map['is_pregnant'] = isPregnant;
    if (hasBleedingDisorders != null) {
      map['has_bleeding_disorders'] = hasBleedingDisorders;
    }
    return map;
  }
}