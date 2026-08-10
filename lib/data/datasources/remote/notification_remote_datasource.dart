import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../models/notification/notification_model.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

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
        statusCode: errorStatusCode(e),
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
        statusCode: errorStatusCode(e),
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
        statusCode: errorStatusCode(e),
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
        statusCode: errorStatusCode(e),
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
        statusCode: errorStatusCode(e),
      );
    }
  }

  /// Kept as a thin wrapper so existing call sites read the same; all the
  /// wording now lives in one place. `describeError` already understands
  /// Laravel's validation bag and overrides unhelpful server text for codes
  /// like 403 and 500.
  String _extractMessage(
    DioException e, {
    required String fallback,
  }) =>
      describeError(e, fallback: fallback);
}