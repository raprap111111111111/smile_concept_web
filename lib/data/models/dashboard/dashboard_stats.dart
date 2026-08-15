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

  /// Items at or below their reorder point.
  final int lowStockItems;

  /// Open batches expiring inside the configured warning window.
  final int expiringBatches;

  /// Stock rows that have gone negative — supplies used beyond what was on
  /// record. Each one is a reconciliation someone still owes.
  final int negativeStock;

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
    this.lowStockItems = 0,
    this.expiringBatches = 0,
    this.negativeStock = 0,
    required this.appointmentsTrend,
    required this.appointmentsTodayByHour,
    required this.newPatientsTrend,
    required this.newPatientsByMonth,
  });

  /// True when anything in the stock cupboard wants attention.
  bool get hasStockWarnings =>
      lowStockItems > 0 || expiringBatches > 0 || negativeStock > 0;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      appointmentsToday: _int(json['appointmentsToday']),
      appointmentsTodayDelta: toDouble(json['appointmentsTodayDelta']),
      newPatients: _int(json['newPatients']),
      newPatientsDelta: toDouble(json['newPatientsDelta']),
      pendingReviews: _int(json['pendingReviews']),
      monthlyRevenue: toDouble(json['monthlyRevenue']),
      monthlyRevenueDelta: toDouble(json['monthlyRevenueDelta']),
      // Default to 0 rather than requiring the keys: an API that has not been
      // deployed with the inventory counters yet must not break the dashboard.
      lowStockItems: _int(json['lowStockItems']),
      expiringBatches: _int(json['expiringBatches']),
      negativeStock: _int(json['negativeStock']),
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
