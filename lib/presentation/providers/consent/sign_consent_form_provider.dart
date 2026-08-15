import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../data/models/consent/consent_form_data.dart';
import '../../../../data/models/patient/patient_model.dart';

// ─── Patient search ─────────────────────────────────────────────────────────
final dialogPatientsProvider =
    FutureProvider.autoDispose.family<List<PatientModel>, String>(
  (ref, search) async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get(
      '/patients',
      queryParameters: {
        'page': 1,
        'per_page': 30,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final body = response.data;
    final list = (body['data'] is List)
        ? body['data'] as List
        : (body['data']?['data'] ?? body['data']?['records'] ?? []) as List;

    return list
        .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// Form State
// ═══════════════════════════════════════════════════════════════════════════
/// Holds every mutable field for the multi-step consent form.
/// Kept in one place so steps can read/write without prop-drilling.
class ConsentFormState {
  // ── Step 0 ─────────────────────────────────────────────────────────────
  final PatientModel? selectedPatient;
  final PatientRelation patientRelation;

  // ── Step 1: Patient Info ───────────────────────────────────────────────
  final String name;
  final String birthdate;
  final String religion;
  final String homeAddress;      // computed full "street, brgy, city, prov, region"
  final String occupation;
  final String dentalInsurance;
  final String effectiveDate;
  final String parentGuardianName;
  final String parentGuardianOccupation;

  // ── PSGC address components ────────────────────────────────────────────
  final String region;
  final String province;
  final String city;
  final String barangay;
  final String street;

  // ── Guardian profile (when signing as guardian) ────────────────────────
  final String guardianName;
  final String guardianRelation;
  final String guardianOccupation;
  final String guardianAddress;

  // ── Step 2: Medical History ────────────────────────────────────────────
  final bool? inGoodHealth;
  final bool? underMedicalTreatment;
  final bool? hadSeriousIllness;
  final bool? wasHospitalized;
  final bool? takesMedications;
  final bool? usesTobacco;
  final bool? usesAlcoholDrugs;
  final bool? hasAllergies;
  final bool? isPregnant;
  final String treatmentCondition;
  final String illnessDetails;
  final String hospitalizationDetails;
  final String medications;
  final String bleedingTime;
  final String bloodType;
  final String bloodPressure;
  final String otherAllergies;
  final String otherConditions;
  final Set<String> selectedConditions;
  final Set<String> selectedAllergies;

  // ── Step 3: Clauses ────────────────────────────────────────────────────
  final Map<String, bool> clauseAgreed;
  final Map<String, String> clauseInitials;

  // ── Step 4: Intraoral ──────────────────────────────────────────────────
  final Map<String, String> intraoralSelections;
  final String? selectedIntraoralConditionKey;

  // ── Step 5: Signature ──────────────────────────────────────────────────
  final SignerRole signerRole;

  const ConsentFormState({
    // Step 0
    this.selectedPatient,
    this.patientRelation = PatientRelation.self,

    // Step 1
    this.name = '',
    this.birthdate = '',
    this.religion = '',
    this.homeAddress = '',
    this.occupation = '',
    this.dentalInsurance = '',
    this.effectiveDate = '',
    this.parentGuardianName = '',
    this.parentGuardianOccupation = '',

    // PSGC
    this.region = '',
    this.province = '',
    this.city = '',
    this.barangay = '',
    this.street = '',

    // Guardian
    this.guardianName = '',
    this.guardianRelation = '',
    this.guardianOccupation = '',
    this.guardianAddress = '',

    // Step 2
    this.inGoodHealth,
    this.underMedicalTreatment,
    this.hadSeriousIllness,
    this.wasHospitalized,
    this.takesMedications,
    this.usesTobacco,
    this.usesAlcoholDrugs,
    this.hasAllergies,
    this.isPregnant,
    this.treatmentCondition = '',
    this.illnessDetails = '',
    this.hospitalizationDetails = '',
    this.medications = '',
    this.bleedingTime = '',
    this.bloodType = '',
    this.bloodPressure = '',
    this.otherAllergies = '',
    this.otherConditions = '',
    this.selectedConditions = const {},
    this.selectedAllergies = const {},

    // Step 3
    this.clauseAgreed = const {},
    this.clauseInitials = const {},

    // Step 4
    this.intraoralSelections = const {},
    this.selectedIntraoralConditionKey,

    // Step 5
    this.signerRole = SignerRole.self,
  });

  ConsentFormState copyWith({
    // Step 0
    PatientModel? selectedPatient,
    bool clearPatient = false,
    PatientRelation? patientRelation,

    // Step 1
    String? name,
    String? birthdate,
    String? religion,
    String? homeAddress,
    String? occupation,
    String? dentalInsurance,
    String? effectiveDate,
    String? parentGuardianName,
    String? parentGuardianOccupation,

    // PSGC
    String? region,
    String? province,
    String? city,
    String? barangay,
    String? street,

    // Guardian
    String? guardianName,
    String? guardianRelation,
    String? guardianOccupation,
    String? guardianAddress,

    // Step 2
    bool? inGoodHealth,
    bool? underMedicalTreatment,
    bool? hadSeriousIllness,
    bool? wasHospitalized,
    bool? takesMedications,
    bool? usesTobacco,
    bool? usesAlcoholDrugs,
    bool? hasAllergies,
    bool? isPregnant,
    String? treatmentCondition,
    String? illnessDetails,
    String? hospitalizationDetails,
    String? medications,
    String? bleedingTime,
    String? bloodType,
    String? bloodPressure,
    String? otherAllergies,
    String? otherConditions,
    Set<String>? selectedConditions,
    Set<String>? selectedAllergies,

    // Step 3
    Map<String, bool>? clauseAgreed,
    Map<String, String>? clauseInitials,

    // Step 4
    Map<String, String>? intraoralSelections,
    String? selectedIntraoralConditionKey,
    bool clearIntraoralKey = false,

    // Step 5
    SignerRole? signerRole,
  }) {
    return ConsentFormState(
      selectedPatient:
          clearPatient ? null : selectedPatient ?? this.selectedPatient,
      patientRelation: patientRelation ?? this.patientRelation,

      // Step 1
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      religion: religion ?? this.religion,
      homeAddress: homeAddress ?? this.homeAddress,
      occupation: occupation ?? this.occupation,
      dentalInsurance: dentalInsurance ?? this.dentalInsurance,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      parentGuardianName: parentGuardianName ?? this.parentGuardianName,
      parentGuardianOccupation:
          parentGuardianOccupation ?? this.parentGuardianOccupation,

      // PSGC
      region: region ?? this.region,
      province: province ?? this.province,
      city: city ?? this.city,
      barangay: barangay ?? this.barangay,
      street: street ?? this.street,

      // Guardian
      guardianName: guardianName ?? this.guardianName,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      guardianOccupation: guardianOccupation ?? this.guardianOccupation,
      guardianAddress: guardianAddress ?? this.guardianAddress,

      // Step 2
      inGoodHealth: inGoodHealth ?? this.inGoodHealth,
      underMedicalTreatment:
          underMedicalTreatment ?? this.underMedicalTreatment,
      hadSeriousIllness: hadSeriousIllness ?? this.hadSeriousIllness,
      wasHospitalized: wasHospitalized ?? this.wasHospitalized,
      takesMedications: takesMedications ?? this.takesMedications,
      usesTobacco: usesTobacco ?? this.usesTobacco,
      usesAlcoholDrugs: usesAlcoholDrugs ?? this.usesAlcoholDrugs,
      hasAllergies: hasAllergies ?? this.hasAllergies,
      isPregnant: isPregnant ?? this.isPregnant,
      treatmentCondition: treatmentCondition ?? this.treatmentCondition,
      illnessDetails: illnessDetails ?? this.illnessDetails,
      hospitalizationDetails:
          hospitalizationDetails ?? this.hospitalizationDetails,
      medications: medications ?? this.medications,
      bleedingTime: bleedingTime ?? this.bleedingTime,
      bloodType: bloodType ?? this.bloodType,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      otherAllergies: otherAllergies ?? this.otherAllergies,
      otherConditions: otherConditions ?? this.otherConditions,
      selectedConditions: selectedConditions ?? this.selectedConditions,
      selectedAllergies: selectedAllergies ?? this.selectedAllergies,

      // Step 3
      clauseAgreed: clauseAgreed ?? this.clauseAgreed,
      clauseInitials: clauseInitials ?? this.clauseInitials,

      // Step 4
      intraoralSelections: intraoralSelections ?? this.intraoralSelections,
      selectedIntraoralConditionKey: clearIntraoralKey
          ? null
          : selectedIntraoralConditionKey ?? this.selectedIntraoralConditionKey,

      // Step 5
      signerRole: signerRole ?? this.signerRole,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Notifier
// ═══════════════════════════════════════════════════════════════════════════
class ConsentFormNotifier extends AutoDisposeNotifier<ConsentFormState> {
  @override
  ConsentFormState build() {
    // Initialise clause maps
    final agreed = <String, bool>{};
    final initials = <String, String>{};
    for (final c in kConsentClauses) {
      agreed[c['key']!] = false;
      initials[c['key']!] = '';
    }
    return ConsentFormState(clauseAgreed: agreed, clauseInitials: initials);
  }

  // ── Patient ────────────────────────────────────────────────────────────
  void selectPatient(PatientModel p) {
    state = state.copyWith(
      selectedPatient: p,
      name: p.name,
    );
  }

  void setPatientRelation(PatientRelation r) =>
      state = state.copyWith(patientRelation: r);

  // ── Step 1 — Patient Info ──────────────────────────────────────────────
  void updatePatientInfo({
    String? name,
    String? birthdate,
    String? religion,
    String? homeAddress,
    String? occupation,
    String? dentalInsurance,
    String? effectiveDate,
    String? parentGuardianName,
    String? parentGuardianOccupation,
    String? guardianName,
    String? guardianRelation,
    String? guardianOccupation,
    String? guardianAddress,
    // ── PSGC ──────────────────────────────────────────────────────────
    String? region,
    String? province,
    String? city,
    String? barangay,
    String? street,
  }) {
    state = state.copyWith(
      name: name,
      birthdate: birthdate,
      religion: religion,
      homeAddress: homeAddress,
      occupation: occupation,
      dentalInsurance: dentalInsurance,
      effectiveDate: effectiveDate,
      parentGuardianName: parentGuardianName,
      parentGuardianOccupation: parentGuardianOccupation,
      guardianName: guardianName,
      guardianRelation: guardianRelation,
      guardianOccupation: guardianOccupation,
      guardianAddress: guardianAddress,
      region: region,
      province: province,
      city: city,
      barangay: barangay,
      street: street,
    );
  }

  // ── Step 2 — Medical ───────────────────────────────────────────────────
  void setMedicalBool(String field, bool? value) {
    state = switch (field) {
      'inGoodHealth' => state.copyWith(inGoodHealth: value),
      'underMedicalTreatment' => state.copyWith(underMedicalTreatment: value),
      'hadSeriousIllness' => state.copyWith(hadSeriousIllness: value),
      'wasHospitalized' => state.copyWith(wasHospitalized: value),
      'takesMedications' => state.copyWith(takesMedications: value),
      'usesTobacco' => state.copyWith(usesTobacco: value),
      'usesAlcoholDrugs' => state.copyWith(usesAlcoholDrugs: value),
      'hasAllergies' => state.copyWith(hasAllergies: value),
      'isPregnant' => state.copyWith(isPregnant: value),
      _ => state,
    };
  }

  void setMedicalText(String field, String value) {
    state = switch (field) {
      'treatmentCondition' => state.copyWith(treatmentCondition: value),
      'illnessDetails' => state.copyWith(illnessDetails: value),
      'hospitalizationDetails' =>
          state.copyWith(hospitalizationDetails: value),
      'medications' => state.copyWith(medications: value),
      'bleedingTime' => state.copyWith(bleedingTime: value),
      'bloodType' => state.copyWith(bloodType: value),
      'bloodPressure' => state.copyWith(bloodPressure: value),
      'otherAllergies' => state.copyWith(otherAllergies: value),
      'otherConditions' => state.copyWith(otherConditions: value),
      _ => state,
    };
  }

  void toggleCondition(String key) {
    final updated = Set<String>.from(state.selectedConditions);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    state = state.copyWith(selectedConditions: updated);
  }

  void toggleAllergy(String key) {
    final updated = Set<String>.from(state.selectedAllergies);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    state = state.copyWith(selectedAllergies: updated);
  }

  // ── Step 3 — Clauses ───────────────────────────────────────────────────
  void toggleClause(String key, bool agreed) {
    final updatedAgreed = Map<String, bool>.from(state.clauseAgreed)
      ..[key] = agreed;
    state = state.copyWith(clauseAgreed: updatedAgreed);
  }

  void setClauseInitial(String key, String initial) {
    final updatedInitials = Map<String, String>.from(state.clauseInitials)
      ..[key] = initial;
    state = state.copyWith(clauseInitials: updatedInitials);
  }

  void autoFillInitials(String initials) {
    final agreed = <String, bool>{};
    final ini = <String, String>{};
    for (final c in kConsentClauses) {
      agreed[c['key']!] = true;
      ini[c['key']!] = initials;
    }
    state = state.copyWith(clauseAgreed: agreed, clauseInitials: ini);
  }

  void clearAllClauses() {
    final agreed = <String, bool>{};
    final ini = <String, String>{};
    for (final c in kConsentClauses) {
      agreed[c['key']!] = false;
      ini[c['key']!] = '';
    }
    state = state.copyWith(clauseAgreed: agreed, clauseInitials: ini);
  }

  // ── Step 4 — Intraoral ─────────────────────────────────────────────────
  void selectIntraoralCondition(String key) =>
      state = state.copyWith(selectedIntraoralConditionKey: key);

  void assignToothCondition(String tooth, String symbol) {
    final updated = Map<String, String>.from(state.intraoralSelections)
      ..[tooth] = symbol;
    state = state.copyWith(intraoralSelections: updated);
  }

  void clearToothCondition(String tooth) {
    final updated = Map<String, String>.from(state.intraoralSelections)
      ..remove(tooth);
    state = state.copyWith(intraoralSelections: updated);
  }

  // ── Step 5 — Signature ─────────────────────────────────────────────────
  void setSignerRole(SignerRole role) =>
      state = state.copyWith(signerRole: role);

  // ── Derived helpers ────────────────────────────────────────────────────
  String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool allClausesAgreed() =>
      kConsentClauses.every((c) => state.clauseAgreed[c['key']!] == true);

  // ── Build payload for API ──────────────────────────────────────────────
  Map<String, dynamic> buildFormPayload() {
    final s = state;
    return {
      'clauses': {
        for (final c in kConsentClauses)
          c['key']!: {
            'agreed': s.clauseAgreed[c['key']!] ?? false,
            'initial': s.clauseInitials[c['key']!] ?? '',
          },
      },
      'patient_info': {
        'name': s.name,
        'birthdate': s.birthdate,
        'religion': s.religion,
        // ── Full formatted address (combined from PSGC parts) ─────────
        'home_address': s.homeAddress,
        // ── Also send individual PSGC components for PDF ──────────────
        'address_region': s.region,
        'address_province': s.province,
        'address_city': s.city,
        'address_barangay': s.barangay,
        'address_street': s.street,
        'occupation': s.occupation,
        'dental_insurance': s.dentalInsurance,
        'effective_date': s.effectiveDate,
        'guardian_name': s.parentGuardianName,
        'guardian_occupation': s.parentGuardianOccupation,
      },
      if (s.patientRelation == PatientRelation.minorDependent)
        'guardian_profile': {
          'guardian_name': s.guardianName,
          'guardian_relationship': s.guardianRelation,
          'guardian_occupation': s.guardianOccupation,
          'guardian_address': s.guardianAddress,
        },
      'medical': {
        'in_good_health': s.inGoodHealth,
        'under_medical_treatment': s.underMedicalTreatment,
        'had_serious_illness': s.hadSeriousIllness,
        'was_hospitalized': s.wasHospitalized,
        'takes_medications': s.takesMedications,
        'uses_tobacco': s.usesTobacco,
        'uses_alcohol_drugs': s.usesAlcoholDrugs,
        'has_allergies': s.hasAllergies,
        'is_pregnant': s.isPregnant,
        'treatment_condition': s.treatmentCondition,
        'illness_details': s.illnessDetails,
        'hospitalization_details': s.hospitalizationDetails,
        'medications': s.medications,
        'bleeding_time': s.bleedingTime,
        'blood_type': s.bloodType,
        'blood_pressure': s.bloodPressure,
        'other_allergies': s.otherAllergies,
        'other_conditions': s.otherConditions,
        'conditions': s.selectedConditions.toList(),
        'allergy_types': s.selectedAllergies.toList(),
      },
      'intraoral': {
        'selections': s.intraoralSelections,
        'legend_key_used': s.selectedIntraoralConditionKey,
      },
    };
  }

  @visibleForTesting
  void reset() => state = build();
}

// ✅ AFTER — provider dies when no widgets watch it
final consentFormProvider =
    NotifierProvider.autoDispose<ConsentFormNotifier, ConsentFormState>(
  ConsentFormNotifier.new,
);