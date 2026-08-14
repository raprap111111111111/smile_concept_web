// test/data/repositories/appointment_settings_repository_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/core/errors/failures.dart';
import 'package:smile_concept_web/data/models/settings/appointment_settings_model.dart';
import 'package:smile_concept_web/data/repositories/appointment_settings_repository.dart';

/// Captures the outgoing request and replays a canned response, matching the
/// adapter pattern already used by doctor_schedule_repository_test.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  final Map<String, dynamic> body;
  final int statusCode;

  _CapturingAdapter(this.body, {this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> serverPayload({
  int slot = 30,
  int buffer = 0,
  List<int> workingDays = const [1, 2, 3, 4, 5, 6],
  List<int> reminderOffsets = const [24, 1],
}) {
  return {
    'appointment_slot_duration': slot,
    'appointment_buffer_minutes': buffer,
    'clinic_opens_at': '09:00',
    'clinic_closes_at': '18:00',
    'lunch_break_start': '12:00',
    'lunch_break_end': '13:00',
    'working_days': workingDays,
    'max_appointments_per_dentist_per_day': 12,
    'max_appointments_per_day': 60,
    'max_concurrent_appointments': 3,
    'booking_lead_time_hours': 2,
    'max_advance_booking_days': 90,
    'allow_same_day_booking': true,
    'max_future_appointments_per_patient': 3,
    'allow_online_booking': true,
    'cancellation_window_hours': 24,
    'late_cancellation_fee': 0,
    'no_show_fee': 0,
    'no_shows_before_block': 3,
    'reminder_offsets': reminderOffsets,
    'send_booking_confirmation_email': true,
    'send_cancellation_email': true,
    'send_followup_email': false,
    'followup_email_hours_after': 24,
    'enable_waitlist': false,
    'waitlist_offer_window_minutes': 120,
  };
}

AppointmentSettingsModel modelOf(Map<String, dynamic> json) =>
    AppointmentSettingsModel.fromJson(json);

void main() {
  group('AppointmentSettingsModel', () {
    test('parses the server payload into typed fields', () {
      final m = modelOf(serverPayload(slot: 45, buffer: 15, workingDays: [1, 3, 5]));

      expect(m.slotDurationMinutes, 45);
      expect(m.bufferMinutes, 15);
      expect(m.clinicOpensAt, '09:00');
      expect(m.workingDays, {1, 3, 5});
      expect(m.firstReminderHours, 24);
      expect(m.secondReminderHours, 1);
    });

    test('splits reminder_offsets into first and second, and rejoins on write', () {
      final m = modelOf(serverPayload(reminderOffsets: [72, 6]));

      expect(m.firstReminderHours, 72);
      expect(m.secondReminderHours, 6);
      expect(m.toJson()['reminder_offsets'], [72, 6]);
    });

    test('tolerates HH:mm:ss and string numerics from the settings table', () {
      final raw = serverPayload()
        ..['clinic_opens_at'] = '08:30:00'
        ..['appointment_slot_duration'] = '45'
        ..['allow_same_day_booking'] = '0'
        ..['late_cancellation_fee'] = '250.50';

      final m = modelOf(raw);

      expect(m.clinicOpensAt, '08:30');
      expect(m.slotDurationMinutes, 45);
      expect(m.allowSameDayBooking, isFalse);
      expect(m.lateCancellationFee, 250.50);
    });

    test('falls back to defaults on missing or malformed values', () {
      final m = modelOf({'working_days': 'nonsense'});

      expect(m.slotDurationMinutes, 30);
      expect(m.clinicOpensAt, '09:00');
      expect(m.workingDays, {1, 2, 3, 4, 5, 6});
      expect(m.firstReminderHours, 24);
    });

    test('equality drives the dirty flag, including nested collections', () {
      final a = modelOf(serverPayload());
      final b = modelOf(serverPayload());

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      // Nested list change must register as dirty.
      expect(a.copyWith(workingDays: {1, 2}), isNot(equals(a)));
      expect(a.copyWith(secondReminderHours: 2), isNot(equals(a)));
      expect(a.copyWith(slotDurationMinutes: 45), isNot(equals(a)));
    });

    test('round-trips through toJson without drift', () {
      final a = modelOf(serverPayload(slot: 45, workingDays: [0, 6]));

      expect(modelOf(a.toJson()), equals(a));
    });
  });

  group('AppointmentSettingsRepository', () {
    late Dio dio;
    late _CapturingAdapter adapter;

    Dio dioWith(_CapturingAdapter a) {
      final d = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'));
      d.httpClientAdapter = a;
      return d;
    }

    test('GET unwraps the success envelope', () async {
      adapter = _CapturingAdapter({
        'success': true,
        'message': 'Appointment settings retrieved.',
        'data': serverPayload(slot: 45),
      });
      dio = dioWith(adapter);

      final result = await AppointmentSettingsRepository(dio).getSettings();

      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.path, '/appointment-settings');
      expect(result.slotDurationMinutes, 45);
    });

    test('PUT sends every key the backend requires', () async {
      adapter = _CapturingAdapter({
        'success': true,
        'message': 'Appointment settings updated.',
        'data': serverPayload(slot: 45),
      });
      dio = dioWith(adapter);

      final draft = modelOf(serverPayload()).copyWith(slotDurationMinutes: 45);
      await AppointmentSettingsRepository(dio).updateSettings(draft);

      final sent = adapter.lastRequest!.data as Map<String, dynamic>;

      expect(adapter.lastRequest!.method, 'PUT');
      expect(sent['appointment_slot_duration'], 45);
      // The backend FormRequest marks all of these required; a missing key is a 422.
      for (final key in serverPayload().keys) {
        expect(sent.containsKey(key), isTrue, reason: 'missing key: $key');
      }
    });

    test('surfaces the 422 validation bag as field errors', () async {
      adapter = _CapturingAdapter({
        'message': 'Lunch break cannot start before the clinic opens.',
        'errors': {
          'lunch_break_start': ['Lunch break cannot start before the clinic opens.'],
          'reminder_offsets': ['The second reminder must be closer to the appointment.'],
        },
      }, statusCode: 422);
      dio = dioWith(adapter);

      try {
        await AppointmentSettingsRepository(dio)
            .updateSettings(modelOf(serverPayload()));
        fail('expected ApiFailure');
      } on ApiFailure catch (f) {
        expect(f.statusCode, 422);
        expect(f.fieldErrors['lunch_break_start'], contains('before the clinic opens'));
        expect(f.fieldErrors['reminder_offsets'], isNotEmpty);
      }
    });
  });
}
