// The patient list rendered Add / Edit / Delete for every role that could
// reach it. A dentist holds patient read-only, so those controls led to
// /unauthorized (Add, Edit) or an API 403 (Delete) — a dead end dressed up as
// an available action.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smile_concept_web/data/models/patient/patient_model.dart';
import 'package:smile_concept_web/data/repositories/patient_repository.dart';
import 'package:smile_concept_web/presentation/pages/patients/patient_list_page.dart';
import 'package:smile_concept_web/presentation/providers/auth/permission_provider.dart';
import 'package:smile_concept_web/presentation/providers/patient/patient_list_provider.dart';

const _patient = PatientModel(
  id: 1,
  userId: 1,
  name: 'Juan Dela Cruz',
  email: 'juan@example.test',
  phone: '09171234567',
  bloodType: 'O+',
);

/// Stands in for the network so the notifier's constructor load resolves.
class _FakePatientRepository implements PatientRepository {
  @override
  Future<PatientPaginatedResult> getAllPaginated({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async =>
      const PatientPaginatedResult(
        patients: [_patient],
        currentPage: 1,
        lastPage: 1,
        perPage: 10,
        total: 1,
        hasMore: false,
      );

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

Future<void> _pumpList(WidgetTester tester, _FakeUser user) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        patientRepositoryProvider.overrideWithValue(_FakePatientRepository()),
        permissionServiceProvider.overrideWithValue(PermissionService(user)),
      ],
      child: const MaterialApp(home: Scaffold(body: PatientsListPage())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a receptionist sees every write action', (tester) async {
    await _pumpList(
      tester,
      const _FakeUser('receptionist', [
        'patient.viewAny',
        'patient.view',
        'patient.create',
        'patient.update',
        'patient.delete',
      ]),
    );

    expect(find.text('Add Patient'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
    expect(find.byTooltip('View'), findsOneWidget);
  });

  testWidgets('a read-only dentist sees only View', (tester) async {
    await _pumpList(
      tester,
      const _FakeUser('dentist', ['patient.viewAny', 'patient.view']),
    );

    expect(find.text('Add Patient'), findsNothing);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Delete'), findsNothing);

    // Still a usable page — the row remains readable.
    expect(find.byTooltip('View'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
  });
}
