// test/data/repositories/doctor_schedule_repository_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/repositories/doctor_schedule_repository.dart';

/// Captures the outgoing request and replays a canned envelope, so the query
/// string the repository actually builds can be asserted without a network or
/// a mocking package.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  final Map<String, dynamic> body;

  _CapturingAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> envelope({
  List<Map<String, dynamic>> records = const [],
  int total = 0,
  bool hasMore = false,
}) {
  return {
    'message': 'ok',
    'data': {
      'records': records,
      'total': total,
      'current_page': 1,
      'last_page': 1,
      'per_page': 15,
      'has_more': hasMore,
    },
  };
}

Map<String, dynamic> scheduleJson({
  int id = 1,
  int branchId = 1,
  int dayOfWeek = 1,
}) {
  return {
    'id': id,
    'doctor_id': 2,
    'branch_id': branchId,
    'day_of_week': dayOfWeek,
    'day_label': 'Monday',
    'start_time': '09:00:00',
    'end_time': '17:00:00',
  };
}

void main() {
  late _CapturingAdapter adapter;
  late DoctorScheduleRepository repository;

  void useResponse(Map<String, dynamic> body) {
    adapter = _CapturingAdapter(body);
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
      ..httpClientAdapter = adapter;
    repository = DoctorScheduleRepository(dio);
  }

  setUp(() => useResponse(envelope()));

  group('getSchedules pagination', () {
    // The endpoint validates `offset`/`limit` and silently drops `page` /
    // `per_page`, so sending those returned page 1 for every request and
    // infinite scroll re-appended the same rows forever.
    test('sends offset and limit, never page or per_page', () async {
      await repository.getSchedules(page: 1, perPage: 15);

      final query = adapter.lastRequest!.queryParameters;
      expect(query['offset'], 0);
      expect(query['limit'], 15);
      expect(query.containsKey('page'), isFalse);
      expect(query.containsKey('per_page'), isFalse);
    });

    test('translates later pages into the matching offset', () async {
      await repository.getSchedules(page: 3, perPage: 15);

      expect(adapter.lastRequest!.queryParameters['offset'], 30);
    });

    test('honours a non-default page size', () async {
      await repository.getSchedules(page: 2, perPage: 50);

      final query = adapter.lastRequest!.queryParameters;
      expect(query['offset'], 50);
      expect(query['limit'], 50);
    });
  });

  group('getSchedules filters', () {
    test('sends branch_id when filtering by branch', () async {
      await repository.getSchedules(branchId: 7);

      expect(adapter.lastRequest!.queryParameters['branch_id'], 7);
    });

    test('omits branch_id entirely when unfiltered', () async {
      await repository.getSchedules();

      expect(
        adapter.lastRequest!.queryParameters.containsKey('branch_id'),
        isFalse,
      );
    });

    test('combines branch and day filters', () async {
      await repository.getSchedules(branchId: 2, dayOfWeek: 6);

      final query = adapter.lastRequest!.queryParameters;
      expect(query['branch_id'], 2);
      expect(query['day_of_week'], 6);
    });

    test('day 0 (Sunday) is sent, not dropped as falsy', () async {
      await repository.getSchedules(dayOfWeek: 0);

      expect(adapter.lastRequest!.queryParameters['day_of_week'], 0);
    });
  });

  group('getSchedules parsing', () {
    test('maps records and the has_more flag', () async {
      useResponse(
        envelope(
          records: [
            scheduleJson(id: 1, branchId: 2),
            scheduleJson(id: 2, branchId: 2, dayOfWeek: 3),
          ],
          total: 2,
          hasMore: true,
        ),
      );

      final result = await repository.getSchedules(branchId: 2);

      expect(result.data.map((s) => s.id), [1, 2]);
      expect(result.data.every((s) => s.branchId == 2), isTrue);
      expect(result.total, 2);
      expect(result.hasNextPage, isTrue);
    });

    test('an empty page reports no next page', () async {
      useResponse(envelope());

      final result = await repository.getSchedules(branchId: 99);

      expect(result.data, isEmpty);
      expect(result.hasNextPage, isFalse);
    });
  });
}
