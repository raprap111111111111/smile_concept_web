import 'package:equatable/equatable.dart';

class ActivityLogModel extends Equatable {
  final int id;
  final int? userId;
  final String? userName;
  final String? action;
  final String? subjectType;
  final int? subjectId;
  final String? logName;
  final String? description;
  final String? event;
  final String? causerType;
  final int? causerId;
  final Map<String, dynamic>? properties;
  final String? batchUuid;
  final String? ipAddress;
  final String? userAgent;
  final String? url;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ActivityLogModel({
    required this.id,
    this.userId,
    this.userName,
    this.action,
    this.subjectType,
    this.subjectId,
    this.logName,
    this.description,
    this.event,
    this.causerType,
    this.causerId,
    this.properties,
    this.batchUuid,
    this.ipAddress,
    this.userAgent,
    this.url,
    this.createdAt,
    this.updatedAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return ActivityLogModel(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      userName: user?['name'] as String? ?? json['user_name'] as String?,
      action: json['action'] as String?,
      subjectType: json['subject_type'] as String?,
      subjectId: json['subject_id'] as int?,
      logName: json['log_name'] as String?,
      description: json['description'] as String?,
      event: json['event'] as String?,
      causerType: json['causer_type'] as String?,
      causerId: json['causer_id'] as int?,
      properties: json['properties'] is Map
          ? Map<String, dynamic>.from(json['properties'] as Map)
          : null,
      batchUuid: json['batch_uuid'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      url: json['url'] as String?,
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
        'user_name': userName,
        'action': action,
        'subject_type': subjectType,
        'subject_id': subjectId,
        'log_name': logName,
        'description': description,
        'event': event,
        'causer_type': causerType,
        'causer_id': causerId,
        'properties': properties,
        'batch_uuid': batchUuid,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'url': url,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Short human-readable label for the activity.
  String get displayAction {
    if (description != null && description!.trim().isNotEmpty) {
      return description!;
    }
    if (action != null && action!.trim().isNotEmpty) {
      return action!;
    }
    if (event != null && event!.trim().isNotEmpty) {
      return event!;
    }
    return 'Activity #$id';
  }

  /// e.g. "PatientConsent #36"
  String get subjectLabel {
    if (subjectType == null) return '';
    final type = subjectType!.split('\\').last;
    if (subjectId != null) return '$type #$subjectId';
    return type;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        action,
        subjectType,
        subjectId,
        createdAt,
      ];
}

/// Paginated result wrapper used by the repository & providers.
class ActivityLogListResult {
  final List<ActivityLogModel> records;
  final int total;
  final int currentPage;
  final int lastPage;
  final int perPage;

  const ActivityLogListResult({
    required this.records,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
  });

  factory ActivityLogListResult.fromJson(Map<String, dynamic> json) {
    // ✅ Backend returns: { records: [...], pagination: {...} }
    final rawList = (json['records'] as List?) ?? [];
    final pagination = (json['pagination'] as Map<String, dynamic>?) ?? {};

    return ActivityLogListResult(
      records: rawList
          .map((e) => ActivityLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? rawList.length,
      currentPage: pagination['current_page'] as int? ?? 1,
      lastPage: pagination['last_page'] as int? ?? 1,
      perPage: pagination['per_page'] as int? ?? 15,
    );
  }
}
