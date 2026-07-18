// The emergency contact section is optional and patient-only, so it has to
// appear for a patient with a medical profile and stay out of everyone
// else's dialog.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smile_concept_web/data/datasources/local/profile_local_datasource.dart';
import 'package:smile_concept_web/data/datasources/remote/profile_remote_datasource.dart';
import 'package:smile_concept_web/data/models/profile/patient_profile_model.dart';
import 'package:smile_concept_web/data/models/profile/profile_model.dart';
import 'package:smile_concept_web/data/repositories/profile_repository.dart';
import 'package:smile_concept_web/presentation/pages/profile/widgets/edit_profile_dialog.dart';

final patientProfile = ProfileModel(
  id: 1,
  name: 'Maria Dela Cruz',
  email: 'maria@example.com',
  role: 'patient',
  patientProfile: const PatientProfileModel(
    id: 1,
    userId: 1,
    emergencyContactName: 'Jose Dela Cruz',
    emergencyContactPhone: '09171234567',
  ),
);

final staffProfile = ProfileModel(
  id: 2,
  name: 'Dr. Juvile Ann',
  email: 'juvile@example.com',
  role: 'super-admin',
);

Future<void> pumpDialog(WidgetTester tester, ProfileModel profile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // The dialog only reads state while rendering, so a repository over an
        // unused Dio is enough to build the notifier.
        profileRepositoryProvider.overrideWithValue(
          ProfileRepository(
            remote: ProfileRemoteDataSource(Dio()),
            local: ProfileLocalDataSource(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: EditProfileDialog(profile: profile)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a patient sees their emergency contact, prefilled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpDialog(tester, patientProfile);

    expect(find.text('Emergency contact'), findsOneWidget);
    expect(find.text('Jose Dela Cruz'), findsOneWidget);
    expect(find.text('09171234567'), findsOneWidget);
  });

  testWidgets('the section is absent for staff', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpDialog(tester, staffProfile);

    expect(find.text('Emergency contact'), findsNothing);
    expect(find.text('Contact name'), findsNothing);
  });

  testWidgets('blanking the fields is allowed by validation', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpDialog(tester, patientProfile);

    await tester.enterText(find.widgetWithText(TextFormField, 'Jose Dela Cruz'), '');
    await tester.enterText(find.widgetWithText(TextFormField, '09171234567'), '');
    await tester.pump();

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isTrue);
  });
}
