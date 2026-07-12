// lib/data/models/prescription/prescription_model.dart

import 'prescription_item_model.dart';

class PrescriptionModel {
  final int id;
  final int? appointmentId;
  final int doctorId;
  final int userId;
  final String? notes;
  final String? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PrescriptionItemModel> items;
  final PrescriptionPatientModel? patient;
  final PrescriptionDoctorModel? doctor;

  const PrescriptionModel({
    required this.id,
    this.appointmentId,
    required this.doctorId,
    required this.userId,
    this.notes,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.patient,
    this.doctor,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      appointmentId: (json['appointment_id'] as num?)?.toInt(),
      doctorId: (json['doctor_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) =>
              PrescriptionItemModel.fromJson(_toStringMap(e as Map)))
          .toList(),
      patient: json['patient'] != null
          ? PrescriptionPatientModel.fromJson(
              _toStringMap(json['patient'] as Map))
          : null,
      doctor: json['doctor'] != null
          ? PrescriptionDoctorModel.fromJson(
              _toStringMap(json['doctor'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'doctor_id': doctorId,
      'user_id': userId,
      'notes': notes,
    };
  }

  bool get hasItems => items.isNotEmpty;
  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  static Map<String, dynamic> _toStringMap(Map source) {
    final result = <String, dynamic>{};
    source.forEach((k, v) => result[k.toString()] = v);
    return result;
  }
}

// ─────────────────────────────────────────────────────────────
// Patient nested model — from your API: { id, name, email, phone }
// ─────────────────────────────────────────────────────────────
class PrescriptionPatientModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;

  const PrescriptionPatientModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
  });

  factory PrescriptionPatientModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionPatientModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Doctor nested model — from your API: { id, name, specialty, license_number }
// ─────────────────────────────────────────────────────────────
class PrescriptionDoctorModel {
  final int id;
  final String name;
  final String? specialty;
  final String? licenseNumber;

  const PrescriptionDoctorModel({
    required this.id,
    required this.name,
    this.specialty,
    this.licenseNumber,
  });

  String get displayName => name;

  factory PrescriptionDoctorModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionDoctorModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Unknown Doctor',
      specialty: json['specialty']?.toString() ?? json['specialization']?.toString(),
      licenseNumber: json['license_number']?.toString(),
    );
  }
}