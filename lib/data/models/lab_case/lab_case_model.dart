// lib/data/models/lab_case/lab_case_model.dart

class LabCaseModel {
  final int id;
  final int appointmentId;
  final String labName;
  final String workType;
  final String status;
  final DateTime sentDate;
  final DateTime dueDate;
  final DateTime? receivedDate;
  final double? cost;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional nested info returned by the API resource
  final String? appointmentCode;
  final String? patientName;

  const LabCaseModel({
    required this.id,
    required this.appointmentId,
    required this.labName,
    required this.workType,
    required this.status,
    required this.sentDate,
    required this.dueDate,
    this.receivedDate,
    this.cost,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.appointmentCode,
    this.patientName,
  });

  factory LabCaseModel.fromJson(Map<String, dynamic> json) {
    return LabCaseModel(
      id: json['id'] as int,
      appointmentId: json['appointment_id'] as int,
      labName: json['lab_name'] as String,
      workType: json['work_type'] as String,
      status: json['status'] as String,
      sentDate: DateTime.parse(json['sent_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      receivedDate: json['received_date'] != null
          ? DateTime.parse(json['received_date'] as String)
          : null,
      cost: json['cost'] != null
          ? double.tryParse(json['cost'].toString())
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      // Nested from API resource
      appointmentCode: json['appointment_code'] as String?,
      patientName: json['patient_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'lab_name': labName,
      'work_type': workType,
      'status': status,
      'sent_date': sentDate.toIso8601String().split('T').first,
      'due_date': dueDate.toIso8601String().split('T').first,
      if (receivedDate != null)
        'received_date':
            receivedDate!.toIso8601String().split('T').first,
      if (cost != null) 'cost': cost,
      if (notes != null) 'notes': notes,
    };
  }

  LabCaseModel copyWith({
    int? id,
    int? appointmentId,
    String? labName,
    String? workType,
    String? status,
    DateTime? sentDate,
    DateTime? dueDate,
    DateTime? receivedDate,
    double? cost,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? appointmentCode,
    String? patientName,
  }) {
    return LabCaseModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      labName: labName ?? this.labName,
      workType: workType ?? this.workType,
      status: status ?? this.status,
      sentDate: sentDate ?? this.sentDate,
      dueDate: dueDate ?? this.dueDate,
      receivedDate: receivedDate ?? this.receivedDate,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      appointmentCode: appointmentCode ?? this.appointmentCode,
      patientName: patientName ?? this.patientName,
    );
  }

  bool get isOverdue =>
      status != 'received' &&
      status != 'fitted' &&
      dueDate.isBefore(DateTime.now());
}

// ─── Pagination wrapper (same shape as AppointmentPaginatedResponse) ──────────

class LabCasePaginatedResponse {
  final List<LabCaseModel> items;
  final int total;
  final int offset;
  final int limit;

  const LabCasePaginatedResponse({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });

  factory LabCasePaginatedResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final records = data['records'] as List<dynamic>? ?? [];
    return LabCasePaginatedResponse(
      items: records
          .map((e) => LabCaseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int? ?? 0,
      offset: data['offset'] as int? ?? 0,
      limit: data['limit'] as int? ?? 15,
    );
  }
}