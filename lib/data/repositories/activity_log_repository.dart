import '../datasources/remote/activity_log_remote_datasource.dart';
import '../models/activity_log/activity_log_model.dart';

/// Repository layer for Activity Logs.
/// Keeps the presentation layer free of Dio / API details.
class ActivityLogRepository {
  final ActivityLogRemoteDataSource _remote;

  ActivityLogRepository(this._remote);

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
  }) {
    return _remote.getActivityLogs(
      page: page,
      perPage: perPage,
      search: search,
      userId: userId,
      action: action,
      subjectType: subjectType,
      subjectId: subjectId,
      sortBy: sortBy,
      sortDir: sortDir,
    );
  }

  Future<ActivityLogModel> getActivityLog(int id) {
    return _remote.getActivityLog(id);
  }
}