// After a successful signup the register page navigates itself, so it has to
// respect permissions the same way the router guard does. A patient sent to
// /dashboard lands on /unauthorized, which is the bug this pins.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:smile_concept_web/core/services/secure_storage_service.dart';
import 'package:smile_concept_web/data/datasources/remote/auth_remote_datasource.dart';
import 'package:smile_concept_web/data/models/auth/login_response.dart';
import 'package:smile_concept_web/data/models/auth/user_model.dart';
import 'package:smile_concept_web/data/repositories/auth_repository.dart';
import 'package:smile_concept_web/presentation/pages/auth/register_page.dart';

/// Mirrors what /auth/register returns for a self-registered patient: no
/// dashboard.view anywhere in the permission list.
final patientResponse = LoginResponse(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: UserModel.fromJson(const {
    'id': 1,
    'name': 'New Patient',
    'email': 'new@example.com',
    'role': 'patient',
    'roles': ['patient'],
    'permissions': ['appointment.view', 'appointment.create', 'invoice.view'],
  }),
);

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository()
      : super(
          remoteDataSource: AuthRemoteDataSource(Dio()),
          secureStorage: SecureStorageService(),
        );

  @override
  Future<LoginResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    return patientResponse;
  }
}

Widget marker(String label) => Scaffold(body: Center(child: Text(label)));

Future<void> pumpAndRegister(WidgetTester tester, {String? next}) async {
  final router = GoRouter(
    initialLocation: next == null ? '/register' : '/register?next=$next',
    routes: [
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/dashboard', builder: (_, __) => marker('DASHBOARD')),
      GoRoute(path: '/appointments', builder: (_, __) => marker('APPOINTMENTS')),
      GoRoute(path: '/patients', builder: (_, __) => marker('PATIENTS')),
      GoRoute(
        path: '/book-appointment',
        builder: (_, __) => marker('BOOKING'),
      ),
      GoRoute(path: '/unauthorized', builder: (_, __) => marker('403')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(find.widgetWithText(TextFormField, 'John'), 'New');
  await tester.enterText(find.widgetWithText(TextFormField, 'Doe'), 'Patient');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'you@example.com'),
    'new@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Create a secure password'),
    'password123',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Re-enter your password'),
    'password123',
  );

  await tester.tap(find.text('Create account'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: 'ENVIRONMENT=testing\nAPI_BASE_URL=http://localhost/api/v1',
    );
  });

  // The viewports below are narrow on purpose: the wide layout renders a
  // marketing panel with a network image, which a widget test cannot load.

  testWidgets('a new patient lands on appointments, not the dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpAndRegister(tester);

    expect(find.text('APPOINTMENTS'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsNothing);
    expect(find.text('403'), findsNothing);
  });

  testWidgets('the booking destination that sent them here is honored', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpAndRegister(tester, next: '/book-appointment');

    expect(find.text('BOOKING'), findsOneWidget);
  });

  testWidgets('a destination the patient cannot open is refused', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpAndRegister(tester, next: '/patients');

    expect(find.text('PATIENTS'), findsNothing);
    expect(find.text('APPOINTMENTS'), findsOneWidget);
  });
}
