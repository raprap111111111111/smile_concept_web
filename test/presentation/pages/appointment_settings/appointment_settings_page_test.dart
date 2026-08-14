// test/presentation/pages/appointment_settings/appointment_settings_page_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/core/network/dio_client.dart';
import 'package:smile_concept_web/presentation/pages/appointment_settings/appointment_settings_page.dart';

class _StubAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Map<String, dynamic> getBody;
  Map<String, dynamic> putBody;
  int putStatus;

  _StubAdapter({
    required this.getBody,
    required this.putBody,
    this.putStatus = 200,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final isPut = options.method == 'PUT';
    return ResponseBody.fromString(
      jsonEncode(isPut ? putBody : getBody),
      isPut ? putStatus : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> payload({int slot = 30}) => {
      'appointment_slot_duration': slot,
      'appointment_buffer_minutes': 0,
      'clinic_opens_at': '09:00',
      'clinic_closes_at': '18:00',
      'lunch_break_start': '12:00',
      'lunch_break_end': '13:00',
      'working_days': [1, 2, 3, 4, 5, 6],
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
      'reminder_offsets': [24, 1],
      'send_booking_confirmation_email': true,
      'send_cancellation_email': true,
      'send_followup_email': false,
      'followup_email_hours_after': 24,
      'enable_waitlist': false,
      'waitlist_offer_window_minutes': 120,
    };

Widget wrap(_StubAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;

  return ProviderScope(
    overrides: [dioProvider.overrideWithValue(dio)],
    // MaterialApp deliberately uses the dark theme the real app runs, so the
    // page's own light-theme pin is exercised rather than bypassed.
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: const AppointmentSettingsPage(),
    ),
  );
}

void main() {
  testWidgets('loads settings and renders every section', (tester) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final adapter = _StubAdapter(getBody: {'data': payload()}, putBody: {'data': payload()});

    await tester.pumpWidget(wrap(adapter));
    await tester.pumpAndSettle();

    expect(find.text('Appointment Settings'), findsOneWidget);
    for (final section in const [
      'Scheduling',
      'Capacity',
      'Booking Window',
      'Cancellation & No-Show',
      'Reminders & Email',
      'Waitlist',
    ]) {
      expect(find.text(section), findsOneWidget, reason: 'missing section: $section');
    }

    // Values from the server are on screen.
    expect(find.text('Default Slot Duration'), findsOneWidget);
    expect(find.widgetWithText(TextField, '30'), findsWidgets);

    // Settings that are stored but not acted on must say so.
    expect(find.text('Not yet enforced'), findsWidgets);

    expect(adapter.requests.single.method, 'GET');
  });

  testWidgets('Save stays disabled until something changes, then PUTs', (tester) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final adapter = _StubAdapter(
      getBody: {'data': payload()},
      putBody: {'data': payload(slot: 45)},
    );

    await tester.pumpWidget(wrap(adapter));
    await tester.pumpAndSettle();

    ElevatedButton saveButton() => tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Save Settings'),
        );

    expect(find.text('All changes saved.'), findsOneWidget);
    expect(saveButton().onPressed, isNull, reason: 'Save must be disabled while clean');

    // Bump the slot duration via its stepper.
    final slotField = find.ancestor(
      of: find.text('Default Slot Duration'),
      matching: find.byType(TextFormField),
    );
    await tester.tap(
      find.descendant(of: slotField, matching: find.byIcon(Icons.add_rounded)),
    );
    await tester.pumpAndSettle();

    expect(find.text('You have unsaved changes.'), findsOneWidget);
    expect(saveButton().onPressed, isNotNull, reason: 'Save must enable once dirty');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Settings'));
    await tester.pumpAndSettle();

    final put = adapter.requests.last;
    expect(put.method, 'PUT');
    expect((put.data as Map)['appointment_slot_duration'], 31);

    // Server response becomes the new baseline, so the form is clean again.
    expect(find.text('All changes saved.'), findsOneWidget);
  });

  testWidgets('a 422 shows the server field error inline', (tester) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final adapter = _StubAdapter(
      getBody: {'data': payload()},
      putBody: {
        'message': 'The given data was invalid.',
        'errors': {
          'max_concurrent_appointments': ['All chairs are already accounted for.'],
        },
      },
      putStatus: 422,
    );

    await tester.pumpWidget(wrap(adapter));
    await tester.pumpAndSettle();

    final field = find.ancestor(
      of: find.text('Max Concurrent Appointments'),
      matching: find.byType(TextFormField),
    );
    await tester.tap(
      find.descendant(of: field, matching: find.byIcon(Icons.add_rounded)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Settings'));
    await tester.pumpAndSettle();

    expect(find.text('All chairs are already accounted for.'), findsWidgets);
    // Still dirty, so the operator can correct and retry.
    expect(find.text('You have unsaved changes.'), findsOneWidget);
  });
}
