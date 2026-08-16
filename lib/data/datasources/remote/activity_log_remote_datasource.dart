import 'package:dio/dio.dart';

import '../../models/activity_log/activity_log_model.dart';

/// Remote data source for Activity Logs.
/// Only talks to the API — no business logic.
class ActivityLogRemoteDataSource {
  final Dio _dio;

  ActivityLogRemoteDataSource(this._dio);

  // ═══════════════════════════════════════════════════════════════════════
  // LIST — paginated with filters
  // ═══════════════════════════════════════════════════════════════════════
  Future<ActivityLogListResult> getActivityLogs({
    int page = 1,
    int perPage = 15,
    String? search,
    int? userId,
    String? action,
    String? subjectType,
    int? subjectId,
    String? sortBy,
    String? sortDir,
  }) async {
    final response = await _dio.get(
      '/activity-logs',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (userId != null) 'user_id': userId,
        if (action != null && action.isNotEmpty) 'action': action,
        if (subjectType != null && subjectType.isNotEmpty)
          'subject_type': subjectType,
        if (subjectId != null) 'subject_id': subjectId,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
        if (sortDir != null && sortDir.isNotEmpty) 'sort_dir': sortDir,
      },
    );

    final body = response.data as Map<String, dynamic>;

    // ✅ Unwrap the ApiResponse envelope { success, message, data: {...} }
    final data = body['data'] as Map<String, dynamic>;

    return ActivityLogListResult.fromJson(data);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHOW — single log by id
  // ═══════════════════════════════════════════════════════════════════════
  Future<ActivityLogModel> getActivityLog(int id) async {
    final response = await _dio.get('/activity-logs/$id');

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? body;

    return ActivityLogModel.fromJson(data);
  }
}
