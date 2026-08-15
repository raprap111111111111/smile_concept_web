// test/presentation/pages/treatment_plans/treatment_plan_form_page_test.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/datasources/remote/treatment_remote_datasource.dart';
import 'package:smile_concept_web/data/models/doctor/doctor_simple_model.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/treatment_plan_form_page.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/grand_total_bar.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/plan_summary_panel.dart';
import 'package:smile_concept_web/presentation/providers/doctor/doctor_list_provider.dart';
import 'package:smile_concept_web/presentation/providers/treatment/treatment_provider.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';

/// The catalog the page loads on first frame.
class _FakeTreatmentDataSource extends TreatmentRemoteDataSource {
  _FakeTreatmentDataSource() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>> fetchTreatments({
    int page = 1,
    bool? isActive,
    String? search,
  }) async {
    return {
      'data': {
        'records': [
          {
            'id': 7,
            'name': 'Deep Cleaning',
            'price': 1500,
            'estimated_duration_minutes': 45,
            'is_active': true,
          },
        ],
        'current_page': 1,
        'last_page': 1,
        'total': 1,
        'has_more': false,
      },
    };
  }
}

void main() {
  /// Hosted under `ThemeData.dark()` because that is what main.dart boots. The
  /// page is expected to pin its own light theme; if that pin is ever dropped
  /// the scaffold below turns dark and these assertions fail.
  Future<void> pumpPage(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          treatmentRemoteDataSourceProvider
              .overrideWithValue(_FakeTreatmentDataSource()),
          doctorSimpleListProvider.overrideWith(
            (ref) async => const [
              DoctorSimpleModel(
                id: 3,
                name: 'Reyes',
                specialization: 'Orthodontics',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const TreatmentPlanFormPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the three-step form on a light surface',
      (tester) async {
    await pumpPage(tester, const Size(1440, 2200));

    // The page pins AppTheme.lightTheme rather than inheriting dark surfaces.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.surface);

    expect(find.text('New Treatment Plan'), findsOneWidget);
    expect(find.textContaining('STEP 1'), findsOneWidget);
    expect(find.textContaining('STEP 2'), findsOneWidget);
    expect(find.textContaining('STEP 3'), findsOneWidget);
    expect(find.text('0 of 3 done'), findsOneWidget);
  });

  testWidgets('wide layout puts the summary rail beside the form',
      (tester) async {
    await pumpPage(tester, const Size(1600, 2200));

    expect(find.byType(PlanSummaryPanel), findsOneWidget);
    expect(find.byType(GrandTotalBar), findsNothing);
    expect(find.text('Still needed (4)'), findsOneWidget);
  });

  testWidgets('narrow layout falls back to the sticky total bar',
      (tester) async {
    await pumpPage(tester, const Size(800, 2400));

    expect(find.byType(GrandTotalBar), findsOneWidget);
    expect(find.byType(PlanSummaryPanel), findsNothing);
    expect(find.text('Missing: Plan name'), findsOneWidget);
  });

  testWidgets('typing a plan name advances the progress bar', (tester) async {
    await pumpPage(tester, const Size(1600, 2200));

    await tester.enterText(
      find.widgetWithText(TextFormField, "e.g. John's Dental Restoration"),
      'Restoration Plan',
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 3 done'), findsOneWidget);
    expect(find.text('Still needed (3)'), findsOneWidget);
    // The summary rail mirrors the name live.
    expect(find.text('Restoration Plan'), findsWidgets);
  });

  testWidgets('submitting an empty form flags every gap at once',
      (tester) async {
    await pumpPage(tester, const Size(1600, 2200));

    await tester.tap(find.text('Create Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Plan name is required'), findsOneWidget);
    expect(find.text('Please select a doctor'), findsOneWidget);
    expect(find.text('Please select a patient'), findsOneWidget);
    expect(find.text('Pick a treatment for this step'), findsOneWidget);
  });

  // A RenderFlex overflow raises in the test framework, so simply pumping each
  // width is the assertion. 1040 is the rail breakpoint; 1060 is the narrowest
  // two-column case, where the form column is squeezed hardest.
  for (final width in <double>[375, 768, 1039, 1040, 1060, 1280, 1920]) {
    testWidgets('lays out without overflow at ${width.toInt()}px',
        (tester) async {
      await pumpPage(tester, Size(width, 2400));
      expect(tester.takeException(), isNull);
      expect(find.text('New Treatment Plan'), findsOneWidget);
    });
  }

  testWidgets('steps can be added and the counter follows', (tester) async {
    await pumpPage(tester, const Size(1600, 2200));

    expect(find.text('0 / 1 step'), findsOneWidget);

    await tester.tap(find.text('Add Another Treatment Step'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 2 steps'), findsOneWidget);
    expect(find.text('0 of 2 set'), findsOneWidget);
  });
}
