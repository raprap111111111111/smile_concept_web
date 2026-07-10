// lib/data/models/auth/doctor_schedule_model.dart

class DoctorProfile {
  final int id;
  final String name;

  const DoctorProfile({required this.id, required this.name});

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}

class DoctorInfo {
  final int id;
  final String specialty;
  final String licenseNumber;
  final DoctorProfile profile;

  const DoctorInfo({
    required this.id,
    required this.specialty,
    required this.licenseNumber,
    required this.profile,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      id: json['id'],
      specialty: json['specialty'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      profile: DoctorProfile.fromJson(json['profile'] ?? {}),
    );
  }
}

class BranchInfo {
  final int id;
  final String name;
  final String branchCode;

  const BranchInfo({
    required this.id,
    required this.name,
    required this.branchCode,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'],
      name: json['name'] ?? '',
      branchCode: json['branch_code'] ?? '',
    );
  }
}

class DoctorScheduleModel {
  final int id;
  final int doctorId;
  final int branchId;
  final int dayOfWeek;
  final String dayLabel;
  final String startTime;
  final String endTime;
  final DoctorInfo? doctor;
  final BranchInfo? branch;
  final String? createdAt;
  final String? updatedAt;

  const DoctorScheduleModel({
    required this.id,
    required this.doctorId,
    required this.branchId,
    required this.dayOfWeek,
    required this.dayLabel,
    required this.startTime,
    required this.endTime,
    this.doctor,
    this.branch,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      branchId: json['branch_id'],
      dayOfWeek: json['day_of_week'],
      dayLabel: json['day_label'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      doctor: json['doctor'] != null
          ? DoctorInfo.fromJson(json['doctor'])
          : null,
      branch: json['branch'] != null
          ? BranchInfo.fromJson(json['branch'])
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctor_id': doctorId,
      'branch_id': branchId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  DoctorScheduleModel copyWith({
    int? id,
    int? doctorId,
    int? branchId,
    int? dayOfWeek,
    String? dayLabel,
    String? startTime,
    String? endTime,
    DoctorInfo? doctor,
    BranchInfo? branch,
  }) {
    return DoctorScheduleModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      branchId: branchId ?? this.branchId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayLabel: dayLabel ?? this.dayLabel,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      doctor: doctor ?? this.doctor,
      branch: branch ?? this.branch,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ─── Paginated Wrapper ────────────────────────────────────────────────────────

class PaginatedSchedules {
  final List<DoctorScheduleModel> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasMore; // ✅ from API has_more field

  const PaginatedSchedules({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    this.hasMore = false,
  });

  bool get hasNextPage => hasMore;
  bool get hasPreviousPage => currentPage > 1;
}