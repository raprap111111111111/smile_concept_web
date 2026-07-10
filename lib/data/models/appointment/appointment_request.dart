// lib/data/models/appointment/appointment_request.dart

class AppointmentRequest {
  final int doctorId;
  final int branchId;
  final DateTime startTime;
  final DateTime endTime;
  final int? userId;
  final String status;
  final String? reasonForVisit;
  final bool reminderSent;

  const AppointmentRequest({
    required this.doctorId,
    required this.branchId,
    required this.startTime,
    required this.endTime,
    this.userId,
    this.status = 'pending',
    this.reasonForVisit,
    this.reminderSent = false,
  });

  Map<String, dynamic> toJson() => {
        'doctor_id': doctorId,
        'branch_id': branchId,
        'start_time': _formatDateTime(startTime),
        'end_time': _formatDateTime(endTime),
        if (userId != null) 'user_id': userId,
        'status': status,
        if (reasonForVisit != null && reasonForVisit!.trim().isNotEmpty)
          'reason_for_visit': reasonForVisit!.trim(),
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
    String? reasonForVisit,
    bool? reminderSent,
  }) {
    return AppointmentRequest(
      doctorId: doctorId ?? this.doctorId,
      branchId: branchId ?? this.branchId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      reasonForVisit: reasonForVisit ?? this.reasonForVisit,
      reminderSent: reminderSent ?? this.reminderSent,
    );
  }
}