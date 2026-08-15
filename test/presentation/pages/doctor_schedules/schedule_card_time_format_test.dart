// test/presentation/pages/doctor_schedules/schedule_card_time_format_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/doctor_schedule/doctor_schedule_model.dart';
import 'package:smile_concept_web/presentation/pages/doctor_schedules/widgets/schedule_card.dart';

DoctorScheduleModel _schedule({
  required String startTime,
  required String endTime,
}) {
  return DoctorScheduleModel(
    id: 1,
    doctorId: 1,
    branchId: 1,
    dayOfWeek: 1,
    dayLabel: 'Monday',
    startTime: startTime,
    endTime: endTime,
  );
}

Future<void> _pump(WidgetTester tester, DoctorScheduleModel schedule) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: ScheduleCard(schedule: schedule),
        ),
      ),
    ),
  );
}

void main() {
  group('ScheduleCard time chip', () {
    testWidgets('renders 12-hour time with AM/PM', (tester) async {
      await _pump(tester, _schedule(startTime: '09:00:00', endTime: '17:30:00'));

      expect(find.text('9:00 AM – 5:30 PM'), findsOneWidget);
    });

    testWidgets('midnight and noon use 12, not 0', (tester) async {
      await _pump(tester, _schedule(startTime: '00:15:00', endTime: '12:00:00'));

      expect(find.text('12:15 AM – 12:00 PM'), findsOneWidget);
    });

    testWidgets('accepts HH:mm without seconds', (tester) async {
      await _pump(tester, _schedule(startTime: '08:05', endTime: '13:45'));

      expect(find.text('8:05 AM – 1:45 PM'), findsOneWidget);
    });

    testWidgets('unparseable values fall through unchanged', (tester) async {
      await _pump(tester, _schedule(startTime: '', endTime: '99:99:99'));

      expect(find.text(' – 99:99:99'), findsOneWidget);
    });
  });
}
