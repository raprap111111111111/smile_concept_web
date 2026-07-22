// lib/data/models/dashboard/chart_series.dart
//
// Shared shapes for every series the dashboard endpoints return. The API
// zero-fills gaps, so a series always has one entry per bucket and the charts
// never have to reason about missing days.

/// A day in the appointment trend: total bookings split by outcome.
class AppointmentTrendPoint {
  final String date;
  final String label;
  final String shortLabel;
  final int total;
  final int completed;
  final int cancelled;

  const AppointmentTrendPoint({
    required this.date,
    required this.label,
    required this.shortLabel,
    required this.total,
    required this.completed,
    required this.cancelled,
  });

  factory AppointmentTrendPoint.fromJson(Map<String, dynamic> json) {
    return AppointmentTrendPoint(
      date: json['date']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      shortLabel: json['shortLabel']?.toString() ?? '',
      total: _toInt(json['total']),
      completed: _toInt(json['completed']),
      cancelled: _toInt(json['cancelled']),
    );
  }
}

/// One clinic hour and how many appointments start inside it.
class HourlyPoint {
  final int hour;
  final String label;
  final int count;

  const HourlyPoint({
    required this.hour,
    required this.label,
    required this.count,
  });

  factory HourlyPoint.fromJson(Map<String, dynamic> json) {
    return HourlyPoint(
      hour: _toInt(json['hour']),
      label: json['label']?.toString() ?? '',
      count: _toInt(json['count']),
    );
  }
}

/// A generic labelled bucket — a day or a month with a single count.
class CountPoint {
  final String key;
  final String label;
  final String shortLabel;
  final int count;

  const CountPoint({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.count,
  });

  factory CountPoint.fromJson(Map<String, dynamic> json) {
    return CountPoint(
      // Daily buckets are keyed by `date`, monthly ones by `month`.
      key: (json['date'] ?? json['month'] ?? '').toString(),
      label: json['label']?.toString() ?? '',
      shortLabel: json['shortLabel']?.toString() ?? '',
      count: _toInt(json['count']),
    );
  }
}

/// A named class with a count — appointment statuses, activity subject types.
class CategoryCount {
  final String key;
  final String label;
  final int count;

  const CategoryCount({
    required this.key,
    required this.label,
    required this.count,
  });

  factory CategoryCount.fromJson(Map<String, dynamic> json) {
    return CategoryCount(
      key: (json['status'] ?? json['type'] ?? json['key'] ?? '').toString(),
      label: json['label']?.toString() ?? '',
      count: _toInt(json['count']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

/// Parses a JSON list into models, tolerating a null or non-list payload.
List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
