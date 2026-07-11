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
      id: json['id'] as int,
      appointmentId: json['appointment_id'] as int?,
      doctorId: json['doctor_id'] as int,
      userId: json['user_id'] as int,
      notes: json['notes'] as String?,
      deletedAt: json['deleted_at'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PrescriptionItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      patient: json['patient'] != null
          ? PrescriptionPatientModel.fromJson(
              json['patient'] as Map<String, dynamic>,
            )
          : null,
      doctor: json['doctor'] != null
          ? PrescriptionDoctorModel.fromJson(
              json['doctor'] as Map<String, dynamic>,
            )
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
}

class PrescriptionPatientModel {
  final int id;
  final String name;
  final String email;
  final String? profilePhotoUrl;

  const PrescriptionPatientModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
  });

  factory PrescriptionPatientModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionPatientModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }
}

class PrescriptionDoctorModel {
  final int id;
  final String? specialization;
  final PrescriptionDoctorUserModel? user;

  const PrescriptionDoctorModel({
    required this.id,
    this.specialization,
    this.user,
  });

  String get displayName => user?.name ?? 'Unknown Doctor';
  String? get profilePhotoUrl => user?.profilePhotoUrl;

  factory PrescriptionDoctorModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionDoctorModel(
      id: json['id'] as int,
      specialization: json['specialization'] as String?,
      user: json['user'] != null
          ? PrescriptionDoctorUserModel.fromJson(
              json['user'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class PrescriptionDoctorUserModel {
  final int id;
  final String name;
  final String? profilePhotoUrl;

  const PrescriptionDoctorUserModel({
    required this.id,
    required this.name,
    this.profilePhotoUrl,
  });

  factory PrescriptionDoctorUserModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionDoctorUserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }
}