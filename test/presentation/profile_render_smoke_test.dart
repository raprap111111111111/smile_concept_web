// Smoke test: render the profile widgets at several viewport widths and fail
// on any layout overflow or paint exception.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smile_concept_web/data/models/profile/branch_summary_model.dart';
import 'package:smile_concept_web/data/models/profile/patient_profile_model.dart';
import 'package:smile_concept_web/data/models/profile/profile_model.dart';
import 'package:smile_concept_web/presentation/pages/profile/widgets/info_card.dart';
import 'package:smile_concept_web/presentation/pages/profile/widgets/medical_info_card.dart';
import 'package:smile_concept_web/presentation/pages/profile/widgets/profile_hero.dart';
import 'package:smile_concept_web/presentation/pages/profile/widgets/profile_info_card.dart';
import 'package:smile_concept_web/presentation/pages/profile/widgets/profile_theme.dart';

final patient = PatientProfileModel(
  id: 1,
  userId: 1,
  bloodType: 'O+',
  allergies: 'Penicillin, latex',
  emergencyContactName: 'Maria Dela Cruz',
  emergencyContactPhone: '09171234567',
  hasCardiacConditions: true,
  isPregnant: true,
);

final profile = ProfileModel(
  id: 1,
  name: 'Dr. Juvile Ann Legislador Mansader',
  email: 'juvileannmansader@gmail.com',
  phone: '09943665968',
  role: 'super-admin',
  branches: const [BranchSummaryModel(id: 1, name: 'Main Branch — Cebu City')],
  emailVerifiedAt: DateTime(2026, 3, 1),
  createdAt: DateTime(2026, 1, 14),
  patientProfile: patient,
);

// Long values + missing values, to stress wrapping and the empty-state style.
final sparseProfile = ProfileModel(
  id: 2,
  name: 'A',
  email: 'a.very.long.email.address.that.should.wrap@subdomain.example.com',
  role: 'patient',
  isActive: false,
  patientProfile: const PatientProfileModel(id: 2, userId: 2),
);

Widget harness(Widget child) {
  return MaterialApp(
    // Mirrors the app root, which is dark — the page must override it.
    theme: ThemeData.dark(),
    home: Builder(
      builder: (context) => Theme(
        data: buildProfileTheme(context),
        child: Scaffold(
          backgroundColor: ProfileTokens.canvas,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  final widths = <double>[375, 600, 768, 960, 1440];

  for (final width in widths) {
    testWidgets('profile widgets render at ${width.toInt()}px', (tester) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        harness(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHero(profile: profile, onEdit: () {}),
              const SizedBox(height: 16),
              ProfileInfoCard(profile: profile),
              const SizedBox(height: 16),
              MedicalInfoCard(patientProfile: patient),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dr. Juvile Ann Legislador Mansader'), findsWidgets);
      expect(find.text('Medical alerts'), findsOneWidget);
    });
  }

  testWidgets('sparse profile renders empty states', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHero(profile: sparseProfile, onEdit: () {}),
            const SizedBox(height: 16),
            ProfileInfoCard(profile: sparseProfile),
            const SizedBox(height: 16),
            MedicalInfoCard(patientProfile: sparseProfile.patientProfile!),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Inactive'), findsWidgets);
    expect(find.text('Not provided'), findsWidgets);
    // Incomplete medical record should surface the warning pill.
    expect(find.text('Incomplete'), findsOneWidget);
  });

  testWidgets('status pill colours resolve against a light card',
      (tester) async {
    await tester.pumpWidget(
      harness(ProfileHero(profile: profile, onEdit: () {})),
    );
    await tester.pumpAndSettle();

    final pill = tester.widget<StatusPill>(
      find.widgetWithText(StatusPill, 'Active'),
    );
    // Guards the dark-on-dark class of bug: foreground must be the darkened
    // text-safe variant, not a raw bright accent.
    expect(pill.foreground, ProfileTokens.success);
    expect(pill.background, ProfileTokens.successSubtle);
  });
}
