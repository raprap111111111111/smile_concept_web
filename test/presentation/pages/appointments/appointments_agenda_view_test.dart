// Patients landed on a calendar with nothing on it and had to guess which
// date to tap before any appointment appeared. They now get an Upcoming/Past
// list by default; staff keep the calendar-first workflow untouched.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:smile_concept_web/data/models/appointment/appointment_model.dart';
import 'package:smile_concept_web/data/models/appointment/paginated_appointment_result.dart';
import 'package:smile_concept_web/data/repositories/appointment_repository.dart';
import 'package:smile_concept_web/data/repositories/auth_repository.dart';
import 'package:smile_concept_web/presentation/pages/appointments/appointments_page.dart';
import 'package:smile_concept_web/presentation/pages/appointments/widgets/appointment_agenda_tile.dart';
import 'package:smile_concept_web/presentation/providers/auth/permission_provider.dart';

final _upcoming = AppointmentModel(
  id: 1,
  userId: 7,
  doctorId: 2,
  branchId: 3,
  startTime: DateTime.now().add(const Duration(days: 3)),
  endTime: DateTime.now().add(const Duration(days: 3, hours: 1)),
  status: AppointmentStatus.confirmed,
  doctor: const AppointmentDoctorModel(id: 2, name: 'Dr. Reyes'),
  branch: const AppointmentBranchModel(id: 3, name: 'Main Branch'),
);

final _past = AppointmentModel(
  id: 2,
  userId: 7,
  doctorId: 2,
  branchId: 3,
  startTime: DateTime.now().subtract(const Duration(days: 30)),
  endTime: DateTime.now().subtract(const Duration(days: 30)).add(
        const Duration(hours: 1),
      ),
  status: AppointmentStatus.completed,
  doctor: const AppointmentDoctorModel(id: 2, name: 'Dr. Reyes'),
  branch: const AppointmentBranchModel(id: 3, name: 'Main Branch'),
);

class _FakeAppointmentRepository implements AppointmentRepository {
  @override
  Future<PaginatedAppointmentResult> getAppointments({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
    int? doctorId,
    int? branchId,
    int? userId,
    String? startDate,
    String? endDate,
  }) async =>
      PaginatedAppointmentResult(
        data: [_upcoming, _past],
        total: 2,
        currentPage: 1,
        lastPage: 1,
        hasNextPage: false,
      );

  @override
  Future<Map<String, Map<String, int>>> getCalendarCounts({
    required DateTime month,
    String? status,
    int? doctorId,
    int? branchId,
    int? userId,
    String? scope,
  }) async =>
      {};

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}

/// The page reads `authStateProvider` for the current user id; without this
/// the real repository reaches for secure storage and the build throws.
class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}

/// PermissionService reads `role` and `permissions` off whatever it is given.
class _FakeUser {
  final String role;
  final List<String> permissions;
  const _FakeUser(this.role, this.permissions);
}

Future<void> _pumpPage(
  WidgetTester tester,
  _FakeUser user, {
  Size size = const Size(1400, 1800),
}) async {
  // A desktop-web viewport: the default 800x600 pushes the calendar's
  // empty-state card past the fold, where it is never built.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appointmentRepositoryProvider
            .overrideWithValue(_FakeAppointmentRepository()),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        permissionServiceProvider.overrideWithValue(PermissionService(user)),
      ],
      child: const MaterialApp(home: AppointmentsPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a patient lands on the agenda list, no date tap needed',
      (tester) async {
    await _pumpPage(
      tester,
      const _FakeUser('patient', ['appointment.view', 'appointment.create']),
    );

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.byType(AppointmentAgendaTile), findsNWidgets(2));

    // The calendar-first dead end is gone.
    expect(find.byType(TableCalendar<AppointmentModel>), findsNothing);
    expect(find.text('Select a date to view appointments'), findsNothing);
  });

  testWidgets('a patient can still switch to the calendar', (tester) async {
    await _pumpPage(
      tester,
      const _FakeUser('patient', ['appointment.view']),
    );

    await tester.tap(find.byTooltip('Calendar view'));
    await tester.pumpAndSettle();

    expect(find.byType(TableCalendar<AppointmentModel>), findsOneWidget);
    expect(find.byType(AppointmentAgendaTile), findsNothing);
  });

  // Canvas rendering means a browser pass cannot inspect layout, so the
  // narrow pump is the only place a header overflow surfaces.
  testWidgets('the agenda header survives a phone-width viewport',
      (tester) async {
    await _pumpPage(
      tester,
      const _FakeUser('patient', ['appointment.view']),
      size: const Size(420, 900),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AppointmentAgendaTile), findsNWidgets(2));

    // The labelled toggle does not fit here; it falls back to icons.
    expect(find.text('Calendar'), findsNothing);
    expect(find.byTooltip('Calendar view'), findsOneWidget);
  });

  testWidgets('a receptionist keeps the calendar-first page', (tester) async {
    await _pumpPage(
      tester,
      const _FakeUser('receptionist', [
        'appointment.viewAny',
        'appointment.view',
        'appointment.update',
      ]),
    );

    expect(find.text('Select a date to view appointments'), findsOneWidget);
    expect(find.byType(TableCalendar<AppointmentModel>), findsOneWidget);

    // The toggle is patient-only.
    expect(find.byTooltip('List view'), findsNothing);
    expect(find.byTooltip('Calendar view'), findsNothing);
  });
}
