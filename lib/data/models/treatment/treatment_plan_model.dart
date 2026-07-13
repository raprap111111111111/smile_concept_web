// lib/data/models/treatment/treatment_plan_model.dart

import 'treatment_model.dart';

class TreatmentPlanModel {
  final int id;
  final int userId;
  final int doctorId;
  final String name;
  final String status;
  final double totalEstimatedAmount;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final List<TreatmentPlanItemModel> items;
  final TreatmentPlanPatientModel? patient;
  final TreatmentPlanDoctorModel? doctor;

  const TreatmentPlanModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.name,
    required this.status,
    required this.totalEstimatedAmount,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.items   = const [],
    this.patient,
    this.doctor,
  });

  factory TreatmentPlanModel.fromJson(Map<String, dynamic> json) {
    return TreatmentPlanModel(
      id:                   _asInt(json['id']),
      userId:               _asInt(json['user_id']),
      doctorId:             _asInt(json['doctor_id']),
      name:                 json['name']?.toString() ?? '',
      status:               json['status']?.toString() ?? 'proposed',
      totalEstimatedAmount: _asDouble(json['total_estimated_amount']),
      notes:                json['notes']?.toString(),
      createdAt:            json['created_at']?.toString(),
      updatedAt:            json['updated_at']?.toString(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => TreatmentPlanItemModel.fromJson(
              _toMap(e as Map)))
          .toList(),
      patient: json['patient'] != null
          ? TreatmentPlanPatientModel.fromJson(
              _toMap(json['patient'] as Map))
          : null,
      doctor: json['doctor'] != null
          ? TreatmentPlanDoctorModel.fromJson(
              _toMap(json['doctor'] as Map))
          : null,
    );
  }

  // ── Status helpers ─────────────────────────────────────────
  bool get isDraft     => status == 'draft';
  bool get isProposed  => status == 'proposed';
  bool get isAccepted  => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isRejected  => status == 'rejected';

  bool get hasItems   => items.isNotEmpty;
  bool get hasNotes   => notes != null && notes!.trim().isNotEmpty;
  bool get hasPatient => patient != null;
  bool get hasDoctor  => doctor != null;

  String get formattedTotal =>
      '₱${totalEstimatedAmount.toStringAsFixed(2)}';

  String get statusLabel {
    return switch (status) {
      'draft'     => 'Draft',
      'proposed'  => 'Proposed',
      'accepted'  => 'Accepted',
      'completed' => 'Completed',
      'rejected'  => 'Rejected',
      _           => status,
    };
  }

  // ── Private helpers ────────────────────────────────────────
  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static Map<String, dynamic> _toMap(Map source) =>
      source.map((k, v) => MapEntry(k.toString(), v));
}

// ── Treatment Plan Item ───────────────────────────────────────
class TreatmentPlanItemModel {
  final int id;
  final int treatmentPlanId;
  final int treatmentId;
  final int sequenceOrder;
  final double estimatedCost;
  final String? notes;
  final TreatmentModel? treatment;

  const TreatmentPlanItemModel({
    required this.id,
    required this.treatmentPlanId,
    required this.treatmentId,
    required this.sequenceOrder,
    required this.estimatedCost,
    this.notes,
    this.treatment,
  });

  factory TreatmentPlanItemModel.fromJson(
      Map<String, dynamic> json) {
    return TreatmentPlanItemModel(
      id:              _asInt(json['id']),
      treatmentPlanId: _asInt(json['treatment_plan_id']),
      treatmentId:     _asInt(json['treatment_id']),
      sequenceOrder:   _asInt(json['sequence_order']),
      estimatedCost:   _asDouble(json['estimated_cost']),
      notes:           json['notes']?.toString(),
      treatment: json['treatment'] != null
          ? TreatmentModel.fromJson(
              _toMap(json['treatment'] as Map))
          : null,
    );
  }

  String get formattedCost =>
      '₱${estimatedCost.toStringAsFixed(2)}';

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static Map<String, dynamic> _toMap(Map source) =>
      source.map((k, v) => MapEntry(k.toString(), v));
}

// ── Nested Patient ────────────────────────────────────────────
class TreatmentPlanPatientModel {
  final int id;
  final String name;
  final String email;

  const TreatmentPlanPatientModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory TreatmentPlanPatientModel.fromJson(
      Map<String, dynamic> json) {
    return TreatmentPlanPatientModel(
      id:    (json['id'] as num?)?.toInt() ?? 0,
      name:  json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

// ── Nested Doctor ─────────────────────────────────────────────
class TreatmentPlanDoctorModel {
  final int id;
  final String name;
  final String? specialization;

  const TreatmentPlanDoctorModel({
    required this.id,
    required this.name,
    this.specialization,
  });

  factory TreatmentPlanDoctorModel.fromJson(
      Map<String, dynamic> json) {
    // doctor.user.name or doctor.name
    final userName = json['user'] != null
        ? (json['user'] as Map)['name']?.toString()
        : json['name']?.toString();

    return TreatmentPlanDoctorModel(
      id:             (json['id'] as num?)?.toInt() ?? 0,
      name:           userName ?? 'Unknown Doctor',
      specialization: json['specialization']?.toString(),
    );
  }
}