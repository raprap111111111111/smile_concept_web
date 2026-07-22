// lib/data/models/dashboard/dashboard_stats.dart
import 'chart_series.dart';

/// Payload of `GET /dashboard/stats` — the four headline counters plus the
/// series the dashboard charts plot.
class DashboardStats {
  final int appointmentsToday;
  final double appointmentsTodayDelta;

  final int newPatients;
  final double newPatientsDelta;

  final int pendingReviews;

  final double monthlyRevenue;
  final double monthlyRevenueDelta;

  final List<AppointmentTrendPoint> appointmentsTrend;
  final List<HourlyPoint> appointmentsTodayByHour;
  final List<CountPoint> newPatientsTrend;
  final List<CountPoint> newPatientsByMonth;

  const DashboardStats({
    required this.appointmentsToday,
    required this.appointmentsTodayDelta,
    required this.newPatients,
    required this.newPatientsDelta,
    required this.pendingReviews,
    required this.monthlyRevenue,
    required this.monthlyRevenueDelta,
    required this.appointmentsTrend,
    required this.appointmentsTodayByHour,
    required this.newPatientsTrend,
    required this.newPatientsByMonth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      appointmentsToday: _int(json['appointmentsToday']),
      appointmentsTodayDelta: toDouble(json['appointmentsTodayDelta']),
      newPatients: _int(json['newPatients']),
      newPatientsDelta: toDouble(json['newPatientsDelta']),
      pendingReviews: _int(json['pendingReviews']),
      monthlyRevenue: toDouble(json['monthlyRevenue']),
      monthlyRevenueDelta: toDouble(json['monthlyRevenueDelta']),
      appointmentsTrend:
          parseList(json['appointmentsTrend'], AppointmentTrendPoint.fromJson),
      appointmentsTodayByHour:
          parseList(json['appointmentsTodayByHour'], HourlyPoint.fromJson),
      newPatientsTrend:
          parseList(json['newPatientsTrend'], CountPoint.fromJson),
      newPatientsByMonth:
          parseList(json['newPatientsByMonth'], CountPoint.fromJson),
    );
  }

  /// Used while loading and when the caller has no data to show.
  static const DashboardStats empty = DashboardStats(
    appointmentsToday: 0,
    appointmentsTodayDelta: 0,
    newPatients: 0,
    newPatientsDelta: 0,
    pendingReviews: 0,
    monthlyRevenue: 0,
    monthlyRevenueDelta: 0,
    appointmentsTrend: [],
    appointmentsTodayByHour: [],
    newPatientsTrend: [],
    newPatientsByMonth: [],
  );
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
