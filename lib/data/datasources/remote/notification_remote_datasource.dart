import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../models/notification/notification_model.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(ref.watch(dioProvider));
});

class NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSource(this.dio);

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    try {
      final response = await dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (unreadOnly != null) 'unread_only': unreadOnly ? 1 : 0,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'];

      List rawList;

      if (data is Map && data['records'] is List) {
        rawList = data['records'] as List;
      } else if (data is Map && data['data'] is List) {
        rawList = data['data'] as List;
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = [];
      }

      return rawList
          .map((item) =>
              NotificationModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to load notifications'),
        code: 'NOTIFICATIONS_FETCH_ERROR',
      );
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get('/notifications/unread-count');

      final body = response.data as Map<String, dynamic>;
      final data = body['data'];

      if (data is Map && data['count'] != null) {
        return int.tryParse(data['count'].toString()) ?? 0;
      }

      return 0;
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to load unread count'),
        code: 'NOTIFICATION_COUNT_ERROR',
      );
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to mark as read'),
        code: 'NOTIFICATION_MARK_READ_ERROR',
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to mark all as read'),
        code: 'NOTIFICATION_MARK_ALL_READ_ERROR',
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await dio.delete('/notifications/$id');
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to delete notification'),
        code: 'NOTIFICATION_DELETE_ERROR',
      );
    }
  }

  String _extractMessage(
    DioException e, {
    required String fallback,
  }) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? fallback;
    }

    return e.message ?? fallback;
  }
}