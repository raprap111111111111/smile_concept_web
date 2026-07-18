// A patient has no dashboard.view, so anything that lands a freshly
// authenticated user on /dashboard bounces them to /unauthorized. These pin
// the destination logic that both the router guard and the register page use.
import 'package:flutter_test/flutter_test.dart';

import 'package:smile_concept_web/presentation/providers/auth/permission_provider.dart';
import 'package:smile_concept_web/presentation/route/router_redirect.dart';

/// PermissionService reads `role` and `permissions` off a dynamic user, so a
/// plain stand-in is enough — no auth stack needed.
class FakeUser {
  FakeUser(this.role, this.permissions);

  final String role;
  final List<String> permissions;
}

final patient = PermissionService(
  FakeUser('patient', [
    'appointment.view',
    'appointment.create',
    'prescription.view',
    'invoice.view',
  ]),
);

final receptionist = PermissionService(
  FakeUser('receptionist', [
    'dashboard.view',
    'appointment.viewAny',
    'patient.viewAny',
  ]),
);

void main() {
  test('a patient lands on appointments, not the dashboard', () {
    expect(postAuthDestination(patient, const {}), '/appointments');
  });

  test('staff with dashboard.view still land on the dashboard', () {
    expect(postAuthDestination(receptionist, const {}), '/dashboard');
  });

  test('a requested destination the user can open is honored', () {
    expect(
      postAuthDestination(patient, const {'next': '/book-appointment'}),
      '/book-appointment',
    );
  });

  test('a requested destination the user cannot open falls back to landing',
      () {
    expect(
      postAuthDestination(patient, const {'next': '/patients'}),
      '/appointments',
    );
  });

  test('an off-site next is dropped', () {
    expect(
      postAuthDestination(patient, const {'next': '//evil.example.com'}),
      '/appointments',
    );
  });

  test('a user with no listed permissions still gets a page they can open', () {
    final stranger = PermissionService(FakeUser('patient', const []));
    expect(postAuthDestination(stranger, const {}), '/profile');
  });
}
