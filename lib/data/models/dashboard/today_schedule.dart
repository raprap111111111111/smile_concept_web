// lib/data/models/dashboard/today_schedule.dart
import 'chart_series.dart';

/// A single row in today's schedule, pre-formatted by the API so the widget
/// does no date maths.
class ScheduleEntry {
  final int id;
  final String time;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final String patientName;
  final String type;
  final String status;
  final String? doctorName;

  const ScheduleEntry({
    required this.id,
    required this.time,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.patientName,
    required this.type,
    required this.status,
    required this.doctorName,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      time: json['time']?.toString() ?? '—',
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      durationMinutes:
          int.tryParse(json['durationMinutes']?.toString() ?? ''),
      patientName: json['patientName']?.toString() ?? 'Unknown Patient',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      doctorName: json['doctorName']?.toString(),
    );
  }
}

/// Payload of `GET /dashboard/appointments-today`.
class TodaySchedule {
  final String date;
  final int total;
  final List<ScheduleEntry> appointments;
  final List<HourlyPoint> byHour;
  final List<CategoryCount> byStatus;

  const TodaySchedule({
    required this.date,
    required this.total,
    required this.appointments,
    required this.byHour,
    required this.byStatus,
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> json) {
    return TodaySchedule(
      date: json['date']?.toString() ?? '',
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      appointments: parseList(json['appointments'], ScheduleEntry.fromJson),
      byHour: parseList(json['byHour'], HourlyPoint.fromJson),
      byStatus: parseList(json['byStatus'], CategoryCount.fromJson),
    );
  }

  static const TodaySchedule empty = TodaySchedule(
    date: '',
    total: 0,
    appointments: [],
    byHour: [],
    byStatus: [],
  );
}
