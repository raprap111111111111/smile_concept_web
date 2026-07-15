// lib/data/models/appointment/appointment_request.dart



class AppointmentRequest {
  final int doctorId;
  final int branchId;
  final DateTime startTime;
  final DateTime endTime;
  final int? userId;
  final String status;
  final String? patientName;
  final String? patientPhone;
  final String? patientEmail;
  final String? reasonForVisit;
  final String? additionalNotes;
  final bool reminderSent;

  const AppointmentRequest({
    required this.doctorId,
    required this.branchId,
    required this.startTime,
    required this.endTime,
    this.userId,
    this.status = 'pending',
    this.patientName,
    this.patientPhone,
    this.patientEmail,
    this.reasonForVisit,
    this.additionalNotes,
    this.reminderSent = false,
  });

  Map<String, dynamic> toJson() => {
        'doctor_id': doctorId,
        'branch_id': branchId,
        'start_time': _formatDateTime(startTime),
        'end_time': _formatDateTime(endTime),
        if (userId != null) 'user_id': userId,
        'status': status,
        if (patientName != null && patientName!.trim().isNotEmpty)
          'patient_name': patientName!.trim(),
        if (patientPhone != null && patientPhone!.trim().isNotEmpty)
          'patient_phone': patientPhone!.trim(),
        if (patientEmail != null && patientEmail!.trim().isNotEmpty)
          'patient_email': patientEmail!.trim(),
        if (reasonForVisit != null && reasonForVisit!.trim().isNotEmpty)
          'reason_for_visit': reasonForVisit!.trim(),
        if (additionalNotes != null && additionalNotes!.trim().isNotEmpty)
          'additional_notes': additionalNotes!.trim(),
        'reminder_sent': reminderSent,
      };

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  AppointmentRequest copyWith({
    int? doctorId,
    int? branchId,
    DateTime? startTime,
    DateTime? endTime,
    int? userId,
    String? status,
    String? patientName,
    String? patientPhone,
    String? patientEmail,
    String? reasonForVisit,
    String? additionalNotes,
    bool? reminderSent,
  }) {
    return AppointmentRequest(
      doctorId: doctorId ?? this.doctorId,
      branchId: branchId ?? this.branchId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      patientEmail: patientEmail ?? this.patientEmail,
      reasonForVisit: reasonForVisit ?? this.reasonForVisit,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      reminderSent: reminderSent ?? this.reminderSent,
    );
  }
}
