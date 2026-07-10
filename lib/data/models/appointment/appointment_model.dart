// lib/data/models/appointment/appointment_model.dart

enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.completed:
        return 'Completed';
    }
  }

  bool get isPending => this == AppointmentStatus.pending;
  bool get isConfirmed => this == AppointmentStatus.confirmed;
  bool get isCancelled => this == AppointmentStatus.cancelled;
  bool get isCompleted => this == AppointmentStatus.completed;

  static AppointmentStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'cancelled':
      case 'canceled':
        return AppointmentStatus.cancelled;
      case 'completed':
        return AppointmentStatus.completed;
      default:
        return AppointmentStatus.pending;
    }
  }
}

class AppointmentUserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;

  const AppointmentUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory AppointmentUserModel.fromJson(Map<String, dynamic> json) {
    return AppointmentUserModel(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
      };
}

class AppointmentDoctorModel {
  final int id;
  final String name;
  final String? specialization;

  const AppointmentDoctorModel({
    required this.id,
    required this.name,
    this.specialization,
  });

  factory AppointmentDoctorModel.fromJson(Map<String, dynamic> json) {
    String name = '';

    if (json['name'] != null) {
      name = json['name'].toString();
    } else if (json['user'] is Map<String, dynamic>) {
      final user = json['user'] as Map<String, dynamic>;
      name = user['name']?.toString() ?? '';
    }

    return AppointmentDoctorModel(
      id: _asInt(json['id']),
      name: name,
      specialization: json['specialization']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (specialization != null) 'specialization': specialization,
      };
}

class AppointmentBranchModel {
  final int id;
  final String name;
  final String? address;

  const AppointmentBranchModel({
    required this.id,
    required this.name,
    this.address,
  });

  factory AppointmentBranchModel.fromJson(Map<String, dynamic> json) {
    return AppointmentBranchModel(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (address != null) 'address': address,
      };
}

class AppointmentModel {
  final int id;
  final int userId;
  final int doctorId;
  final int branchId;

  final DateTime startTime;
  final DateTime endTime;

  final AppointmentStatus status;

  final String? reasonForVisit;
  final String? cancellationReason;
  final int? createdBy;
  final bool reminderSent;

  final int? invoiceId;
  final bool hasInvoice;

  final AppointmentUserModel? user;
  final AppointmentDoctorModel? doctor;
  final AppointmentBranchModel? branch;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.branchId,
    required this.startTime,
    required this.endTime,
    this.status = AppointmentStatus.pending,
    this.reasonForVisit,
    this.cancellationReason,
    this.createdBy,
    this.reminderSent = false,
    this.invoiceId,
    this.hasInvoice = false,
    this.user,
    this.doctor,
    this.branch,
    this.createdAt,
    this.updatedAt,
  });

  bool get canConfirm => status == AppointmentStatus.pending;
  bool get canComplete => status == AppointmentStatus.confirmed;
  bool get canCancel =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  bool get canInvoice => status == AppointmentStatus.completed && !hasInvoice;
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  Duration get duration => endTime.difference(startTime);

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final invoice = json['invoice'];

    return AppointmentModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      doctorId: _asInt(json['doctor_id']),
      branchId: _asInt(json['branch_id']),
      startTime: _parseDate(json['start_time']),
      endTime: _parseDate(json['end_time']),
      status: AppointmentStatusX.fromString(json['status']?.toString()),
      reasonForVisit: json['reason_for_visit']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      createdBy: json['created_by'] != null ? _asInt(json['created_by']) : null,
      reminderSent: json['reminder_sent'] == true ||
          json['reminder_sent'] == 1 ||
          json['reminder_sent'] == '1',
      invoiceId: json['invoice_id'] != null
          ? _asInt(json['invoice_id'])
          : invoice is Map<String, dynamic>
              ? _asInt(invoice['id'])
              : null,
      hasInvoice: json['has_invoice'] == true ||
          json['invoice_id'] != null ||
          invoice != null,
      user: json['user'] is Map<String, dynamic>
          ? AppointmentUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      doctor: json['doctor'] is Map<String, dynamic>
          ? AppointmentDoctorModel.fromJson(
              json['doctor'] as Map<String, dynamic>,
            )
          : null,
      branch: json['branch'] is Map<String, dynamic>
          ? AppointmentBranchModel.fromJson(
              json['branch'] as Map<String, dynamic>,
            )
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'doctor_id': doctorId,
        'branch_id': branchId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'status': status.name,
        'reason_for_visit': reasonForVisit,
        'cancellation_reason': cancellationReason,
        'created_by': createdBy,
        'reminder_sent': reminderSent,
        'invoice_id': invoiceId,
        'has_invoice': hasInvoice,
        'user': user?.toJson(),
        'doctor': doctor?.toJson(),
        'branch': branch?.toJson(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  AppointmentModel copyWith({
    int? id,
    int? userId,
    int? doctorId,
    int? branchId,
    DateTime? startTime,
    DateTime? endTime,
    AppointmentStatus? status,
    String? reasonForVisit,
    String? cancellationReason,
    int? createdBy,
    bool? reminderSent,
    int? invoiceId,
    bool? hasInvoice,
    AppointmentUserModel? user,
    AppointmentDoctorModel? doctor,
    AppointmentBranchModel? branch,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearReasonForVisit = false,
    bool clearCancellationReason = false,
    bool clearInvoice = false,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      branchId: branchId ?? this.branchId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      reasonForVisit:
          clearReasonForVisit ? null : reasonForVisit ?? this.reasonForVisit,
      cancellationReason: clearCancellationReason
          ? null
          : cancellationReason ?? this.cancellationReason,
      createdBy: createdBy ?? this.createdBy,
      reminderSent: reminderSent ?? this.reminderSent,
      invoiceId: clearInvoice ? null : invoiceId ?? this.invoiceId,
      hasInvoice: clearInvoice ? false : hasInvoice ?? this.hasInvoice,
      user: user ?? this.user,
      doctor: doctor ?? this.doctor,
      branch: branch ?? this.branch,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppointmentModel(id: $id, status: ${status.name}, startTime: $startTime)';
  }
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is double) return v.toInt();
  return 0;
}

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}