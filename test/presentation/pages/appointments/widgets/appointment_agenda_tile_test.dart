import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smile_concept_web/data/models/appointment/appointment_model.dart';
import 'package:smile_concept_web/presentation/pages/appointments/widgets/appointment_agenda_tile.dart';

final _appointment = AppointmentModel(
  id: 1,
  userId: 7,
  doctorId: 2,
  branchId: 3,
  startTime: DateTime(2026, 8, 14, 9, 30),
  endTime: DateTime(2026, 8, 14, 10, 30),
  status: AppointmentStatus.confirmed,
  doctor: const AppointmentDoctorModel(id: 2, name: 'Dr. Reyes'),
  branch: const AppointmentBranchModel(id: 3, name: 'Main Branch'),
);

void main() {
  testWidgets('shows date, time and clinician, and reports taps',
      (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppointmentAgendaTile(
            appointment: _appointment,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('AUG'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('9:30 AM – 10:30 AM'), findsOneWidget);
    expect(find.text('Dr. Reyes'), findsOneWidget);
    expect(find.text('Main Branch'), findsOneWidget);
    expect(find.text('CONFIRMED'), findsOneWidget);

    await tester.tap(find.byType(AppointmentAgendaTile));
    expect(taps, 1);
  });

  // The app renders to canvas, so a browser pass cannot inspect layout —
  // a narrow pump is the only place an overflow surfaces.
  testWidgets('lays out at phone width without overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppointmentAgendaTile(
            appointment: _appointment,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Dr. Reyes'), findsOneWidget);
  });

  testWidgets('names the gap when no doctor or branch is set', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppointmentAgendaTile(
            appointment: AppointmentModel(
              id: 2,
              userId: 7,
              doctorId: 2,
              branchId: 3,
              startTime: DateTime(2026, 8, 14, 9, 30),
              endTime: DateTime(2026, 8, 14, 10, 30),
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('No doctor assigned'), findsOneWidget);
    expect(find.text('No branch'), findsOneWidget);
  });
}
