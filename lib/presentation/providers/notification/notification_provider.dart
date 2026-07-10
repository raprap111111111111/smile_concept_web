import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/notification/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

class NotificationListState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final bool unreadOnly;

  const NotificationListState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadOnly = false,
  });

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    bool? unreadOnly,
    bool clearError = false,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>(
  (ref) {
    return NotificationListNotifier(
      ref.watch(notificationRepositoryProvider),
      ref,
    );
  },
);

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationListNotifier(this._repository, this._ref)
      : super(const NotificationListState());

  Future<void> load({
    bool unreadOnly = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      unreadOnly: unreadOnly,
      clearError: true,
    );

    try {
      final notifications = await _repository.getNotifications(
        unreadOnly: unreadOnly ? true : null,
      );

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        clearError: true,
      );

      _ref.invalidate(unreadNotificationCountProvider);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await load(unreadOnly: state.unreadOnly);
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    await refresh();
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
    await refresh();
  }
}