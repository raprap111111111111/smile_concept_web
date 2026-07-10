// lib/data/models/appointment/availability_model.dart

class TimeSlot {
  final String startTime;
  final String endTime;
  final bool isAvailable;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        isAvailable: json['is_available'] as bool? ?? true,
      );

  // Parse to DateTime for display
  DateTime get startDateTime => DateTime.parse(startTime);
  DateTime get endDateTime => DateTime.parse(endTime);
}

class AvailabilityResponse {
  final List<TimeSlot> slots;
  final String date;
  final int doctorId;
  final int branchId;

  const AvailabilityResponse({
    required this.slots,
    required this.date,
    required this.doctorId,
    required this.branchId,
  });

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) {
    final slotsList = json['slots'] as List<dynamic>? ?? [];
    return AvailabilityResponse(
      slots: slotsList
          .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      date: json['date'] as String? ?? '',
      doctorId: json['doctor_id'] as int? ?? 0,
      branchId: json['branch_id'] as int? ?? 0,
    );
  }

  bool get hasAvailableSlots => slots.any((s) => s.isAvailable);
}