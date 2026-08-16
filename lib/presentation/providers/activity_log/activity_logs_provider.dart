import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../data/datasources/remote/activity_log_remote_datasource.dart';
import '../../../data/models/activity_log/activity_log_model.dart';
import '../../../data/repositories/activity_log_repository.dart';

// Dependencies

final activityLogRemoteDataSourceProvider =
    Provider<ActivityLogRemoteDataSource>((ref) {
  return ActivityLogRemoteDataSource(ref.watch(dioProvider));
});

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  return ActivityLogRepository(ref.watch(activityLogRemoteDataSourceProvider));
});

// Filter / Query params

class ActivityLogsParams {
  final int page;
  final int pageSize;
  final String search;
  final int? userId;
  final String? action;
  final String? subjectType;
  final int? subjectId;
  final String sortBy;
  final String sortDir;

  const ActivityLogsParams({
    this.page = 1,
    this.pageSize = 15,
    this.search = '',
    this.userId,
    this.action,
    this.subjectType,
    this.subjectId,
    this.sortBy = 'created_at',
    this.sortDir = 'desc',
  });

  ActivityLogsParams copyWith({
    int? page,
    int? pageSize,
    String? search,
    int? userId,
    String? action,
    String? subjectType,
    int? subjectId,
    String? sortBy,
    String? sortDir,
    bool clearUserId = false,
    bool clearAction = false,
    bool clearSubjectType = false,
    bool clearSubjectId = false,
  }) {
    return ActivityLogsParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      userId: clearUserId ? null : (userId ?? this.userId),
      action: clearAction ? null : (action ?? this.action),
      subjectType: clearSubjectType ? null : (subjectType ?? this.subjectType),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogsParams &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          pageSize == other.pageSize &&
          search == other.search &&
          userId == other.userId &&
          action == other.action &&
          subjectType == other.subjectType &&
          subjectId == other.subjectId &&
          sortBy == other.sortBy &&
          sortDir == other.sortDir;

  @override
  int get hashCode => Object.hash(
        page,
        pageSize,
        search,
        userId,
        action,
        subjectType,
        subjectId,
        sortBy,
        sortDir,
      );
}

// List provider (family)  used by the Activity Logs page

final activityLogsProvider = FutureProvider.autoDispose
    .family<ActivityLogListResult, ActivityLogsParams>((ref, params) async {
  final repo = ref.watch(activityLogRepositoryProvider);

  return repo.getActivityLogs(
    page: params.page,
    perPage: params.pageSize,
    search: params.search.isEmpty ? null : params.search,
    userId: params.userId,
    action: params.action,
    subjectType: params.subjectType,
    subjectId: params.subjectId,
    sortBy: params.sortBy,
    sortDir: params.sortDir,
  );
});

// Single activity log provider

final activityLogDetailProvider =
    FutureProvider.autoDispose.family<ActivityLogModel, int>((ref, id) async {
  final repo = ref.watch(activityLogRepositoryProvider);
  return repo.getActivityLog(id);
});

// UI filter state (keeps search / page in one place)

// Change this:

class ActivityLogsFilterNotifier extends Notifier<ActivityLogsParams> {
  @override
  ActivityLogsParams build() => const ActivityLogsParams();

  void setSearch(String value) {
    state = state.copyWith(search: value, page: 1);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void setPageSize(int size) {
    state = state.copyWith(pageSize: size, page: 1);
  }

  void setAction(String? action) {
    state = state.copyWith(
      action: action,
      clearAction: action == null,
      page: 1,
    );
  }

  void setSubjectType(String? type) {
    state = state.copyWith(
      subjectType: type,
      clearSubjectType: type == null,
      page: 1,
    );
  }

  void setUserId(int? userId) {
    state = state.copyWith(
      userId: userId,
      clearUserId: userId == null,
      page: 1,
    );
  }

  void setSort({String? sortBy, String? sortDir}) {
    state = state.copyWith(
      sortBy: sortBy,
      sortDir: sortDir,
      page: 1,
    );
  }

  void reset() {
    state = const ActivityLogsParams();
  }
}

final activityLogsFilterProvider =
    NotifierProvider<ActivityLogsFilterNotifier, ActivityLogsParams>(
  ActivityLogsFilterNotifier.new,
);

/// Convenience provider that watches the current filter + fetches data.
final filteredActivityLogsProvider =
    Provider.autoDispose<AsyncValue<ActivityLogListResult>>((ref) {
  final params = ref.watch(activityLogsFilterProvider);
  return ref.watch(activityLogsProvider(params));
});