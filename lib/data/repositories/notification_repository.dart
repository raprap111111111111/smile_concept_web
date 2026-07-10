import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/remote/notification_remote_datasource.dart';
import '../models/notification/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    remote: ref.watch(notificationRemoteDataSourceProvider),
  );
});

class NotificationRepository {
  final NotificationRemoteDataSource _remote;

  NotificationRepository({
    required NotificationRemoteDataSource remote,
  }) : _remote = remote;

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) {
    return _remote.getNotifications(
      page: page,
      limit: limit,
      unreadOnly: unreadOnly,
    );
  }

  Future<int> getUnreadCount() {
    return _remote.getUnreadCount();
  }

  Future<void> markAsRead(String id) {
    return _remote.markAsRead(id);
  }

  Future<void> markAllAsRead() {
    return _remote.markAllAsRead();
  }

  Future<void> deleteNotification(String id) {
    return _remote.deleteNotification(id);
  }
}