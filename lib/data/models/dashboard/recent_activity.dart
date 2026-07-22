// lib/data/models/dashboard/recent_activity.dart
import 'chart_series.dart';

/// One audit-log line, already summarised and humanised by the API.
class ActivityEntry {
  final int id;
  final String action;
  final String subjectType;
  final String patientName;
  final String description;
  final String timeAgo;
  final String? createdAt;

  const ActivityEntry({
    required this.id,
    required this.action,
    required this.subjectType,
    required this.patientName,
    required this.description,
    required this.timeAgo,
    required this.createdAt,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      action: json['action']?.toString() ?? '',
      subjectType: json['subjectType']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'System',
      description: json['description']?.toString() ?? '',
      timeAgo: json['timeAgo']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// Payload of `GET /dashboard/recent-activity`.
class RecentActivityFeed {
  final List<ActivityEntry> activities;
  final List<CategoryCount> byType;
  final List<CountPoint> byDay;

  const RecentActivityFeed({
    required this.activities,
    required this.byType,
    required this.byDay,
  });

  factory RecentActivityFeed.fromJson(Map<String, dynamic> json) {
    return RecentActivityFeed(
      activities: parseList(json['activities'], ActivityEntry.fromJson),
      byType: parseList(json['byType'], CategoryCount.fromJson),
      byDay: parseList(json['byDay'], CountPoint.fromJson),
    );
  }

  static const RecentActivityFeed empty = RecentActivityFeed(
    activities: [],
    byType: [],
    byDay: [],
  );
}
