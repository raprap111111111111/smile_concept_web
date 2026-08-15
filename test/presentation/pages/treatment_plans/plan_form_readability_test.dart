// test/presentation/pages/treatment_plans/plan_form_readability_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/patient/patient_model.dart';
import 'package:smile_concept_web/data/models/treatment/treatment_model.dart';
import 'package:smile_concept_web/data/models/treatment/treatment_plan_model.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/form_section_card.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/grand_total_bar.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/patient_picker_field.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/plan_item_card.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/plan_summary_panel.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/treatment_picker_field.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';

/// `main.dart` runs `ThemeData.dark()`, but the treatment-plan builder paints
/// light `AppColors` panels. Anything that took its colour from the ambient
/// theme rendered as a dark block — or near-white text — inside a white card.
/// Every widget below is hosted under the real dark theme so a regression
/// reproduces the actual bug rather than a lab-clean default.
void main() {
  Future<void> pumpDarkHosted(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          // The colour the form's panels actually are.
          backgroundColor: AppColors.background,
          body: Material(
            color: AppColors.background,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  void expectReadableOnLightCard(Color? color, String what) {
    expect(color, isNotNull, reason: '$what colour was inherited, not set');
    final lum = color!.computeLuminance();
    expect(
      lum,
      lessThan(0.5),
      reason: '$what has luminance $lum — too light to read on the '
          'white card',
    );
  }

  // `.first` because a picked treatment name shows both in the step header and
  // inside the picker field below it.
  Color? textColor(WidgetTester tester, String data) =>
      tester.widget<Text>(find.text(data).first).style?.color;

  const cleaning = TreatmentModel(
    id: 7,
    name: 'Deep Cleaning',
    price: 1500,
    estimatedDurationMinutes: 45,
  );

  const jane = PatientModel(
    id: 1,
    userId: 11,
    name: 'Jane Cruz',
    email: 'jane@example.com',
    phone: '0917 555 0101',
  );

  TreatmentPlanItemForm makeItem(
    WidgetTester tester, {
    TreatmentModel? treatment,
    int quantity = 1,
  }) {
    final item = TreatmentPlanItemForm()
      ..selectedTreatment = treatment
      ..quantity = quantity;
    addTearDown(item.dispose);
    return item;
  }

  group('PlanItemCard', () {
    testWidgets('step header stays dark on the light panel', (tester) async {
      final item = makeItem(tester, treatment: cleaning, quantity: 2);

      await pumpDarkHosted(
        tester,
        PlanItemCard(
          index: 0,
          item: item,
          availableTreatments: const [cleaning],
          isLoading: false,
          onChanged: () {},
        ),
      );

      expectReadableOnLightCard(
        textColor(tester, 'Deep Cleaning'),
        'step title',
      );
      // Header recap: subtotal, quantity and duration on one line.
      expect(find.textContaining('₱3,000.00'), findsWidgets);
      expect(find.textContaining('Qty 2'), findsOneWidget);
    });

    testWidgets('prices use pesos, never dollars', (tester) async {
      final item = makeItem(tester, treatment: cleaning);

      await pumpDarkHosted(
        tester,
        PlanItemCard(
          index: 0,
          item: item,
          availableTreatments: const [cleaning],
          isLoading: false,
          onChanged: () {},
        ),
      );

      expect(find.textContaining(r'$'), findsNothing);
      expect(find.text('₱1,500.00'), findsWidgets);
    });

    testWidgets('quantity stepper raises the subtotal', (tester) async {
      final item = makeItem(tester, treatment: cleaning);
      var changes = 0;

      await pumpDarkHosted(
        tester,
        PlanItemCard(
          index: 0,
          item: item,
          availableTreatments: const [cleaning],
          isLoading: false,
          onChanged: () => changes++,
        ),
      );

      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(item.quantity, 2);
      expect(changes, 1);
      expect(item.subtotal, 3000);
    });

    testWidgets('unset step reads as an error, not as blank space',
        (tester) async {
      final item = makeItem(tester)..treatmentError = true;

      await pumpDarkHosted(
        tester,
        PlanItemCard(
          index: 2,
          item: item,
          availableTreatments: const [cleaning],
          isLoading: false,
          onChanged: () {},
        ),
      );

      // Colour is never the only signal — an icon and a sentence go with it.
      expect(find.text('Pick a treatment for this step'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expectReadableOnLightCard(
        textColor(tester, 'No treatment selected'),
        'empty step title',
      );
    });
  });

  group('TreatmentPickerField', () {
    testWidgets('selected treatment stays readable', (tester) async {
      final item = makeItem(tester, treatment: cleaning);

      await pumpDarkHosted(
        tester,
        TreatmentPickerField(
          item: item,
          treatments: const [cleaning],
          isLoading: false,
          onChanged: () {},
        ),
      );

      expectReadableOnLightCard(
        textColor(tester, 'Deep Cleaning'),
        'picked treatment name',
      );
      expect(find.text('₱1,500.00  ·  45 min'), findsOneWidget);
    });

    testWidgets('catalog dialog opens on a light surface', (tester) async {
      final item = makeItem(tester);

      await pumpDarkHosted(
        tester,
        TreatmentPickerField(
          item: item,
          treatments: const [cleaning],
          isLoading: false,
          onChanged: () {},
        ),
      );

      await tester.tap(find.text('Browse the treatment catalog'));
      await tester.pumpAndSettle();

      expect(find.text('Select Treatment'), findsOneWidget);
      expect(find.text('1 treatment in catalog'), findsOneWidget);

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, AppColors.background);

      expectReadableOnLightCard(
        textColor(tester, 'Select Treatment'),
        'dialog title',
      );
    });
  });

  group('PatientPickerField', () {
    testWidgets('picked patient stays readable', (tester) async {
      await pumpDarkHosted(
        tester,
        PatientPickerField(selected: jane, onPicked: (_) {}),
      );

      expectReadableOnLightCard(textColor(tester, 'Jane Cruz'), 'patient name');
      expect(find.text('0917 555 0101  ·  jane@example.com'), findsOneWidget);
    });

    testWidgets('error state names the problem', (tester) async {
      await pumpDarkHosted(
        tester,
        PatientPickerField(selected: null, hasError: true, onPicked: (_) {}),
      );

      expect(find.text('Please select a patient'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('FormSectionCard', () {
    testWidgets('marks a finished section complete', (tester) async {
      await pumpDarkHosted(
        tester,
        const FormSectionCard(
          step: 2,
          complete: true,
          icon: Icons.groups_outlined,
          title: 'Participants',
          subtitle: 'Who is this for?',
          child: SizedBox.shrink(),
        ),
      );

      expect(find.textContaining('STEP 2'), findsOneWidget);
      expect(find.textContaining('Complete'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expectReadableOnLightCard(
        textColor(tester, 'Participants'),
        'section title',
      );
    });

    testWidgets('an unfinished section reads as required', (tester) async {
      await pumpDarkHosted(
        tester,
        const FormSectionCard(
          step: 1,
          icon: Icons.assignment_outlined,
          title: 'Plan Information',
          subtitle: 'Name the plan',
          child: SizedBox.shrink(),
        ),
      );

      expect(find.textContaining('Required'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });
  });

  group('PlanSummaryPanel', () {
    Widget panel({
      required List<TreatmentPlanItemForm> items,
      required List<PlanRequirement> requirements,
      PatientModel? patient,
      String? doctorLabel,
      String planName = 'Restoration Plan',
    }) {
      return PlanSummaryPanel(
        planName: planName,
        patient: patient,
        doctorLabel: doctorLabel,
        items: items,
        requirements: requirements,
        isSubmitting: false,
        onSubmit: () {},
        onCancel: () {},
      );
    }

    testWidgets('totals the picked steps in pesos', (tester) async {
      final items = [
        makeItem(tester, treatment: cleaning, quantity: 2),
        makeItem(tester, treatment: cleaning),
      ];

      await pumpDarkHosted(
        tester,
        panel(
          items: items,
          patient: jane,
          doctorLabel: 'Dr. Reyes',
          requirements: const [
            PlanRequirement('Plan name', met: true),
            PlanRequirement('Patient', met: true),
            PlanRequirement('Doctor', met: true),
            PlanRequirement('A treatment on every step', met: true),
          ],
        ),
      );

      expect(find.text('₱4,500.00'), findsOneWidget);
      expect(find.text('2 of 2 set'), findsOneWidget);
      expect(find.text('Ready to create'), findsOneWidget);
      expectReadableOnLightCard(textColor(tester, 'Jane Cruz'), 'patient row');
    });

    testWidgets('lists exactly what is still missing', (tester) async {
      final items = [makeItem(tester)];

      await pumpDarkHosted(
        tester,
        panel(
          planName: '',
          items: items,
          requirements: const [
            PlanRequirement('Plan name', met: false),
            PlanRequirement('Patient', met: false),
            PlanRequirement('Doctor', met: true),
            PlanRequirement('A treatment on every step', met: false),
          ],
        ),
      );

      expect(find.text('Still needed (3)'), findsOneWidget);
      expect(find.text('• Plan name'), findsOneWidget);
      expect(find.text('• Patient'), findsOneWidget);
      expect(find.text('• A treatment on every step'), findsOneWidget);
      expect(find.text('• Doctor'), findsNothing);

      expect(find.text('Untitled plan'), findsOneWidget);
      expect(find.text('₱0.00'), findsOneWidget);
    });

    testWidgets('submit fires from the rail', (tester) async {
      var submitted = 0;
      final items = [makeItem(tester, treatment: cleaning)];

      await pumpDarkHosted(
        tester,
        PlanSummaryPanel(
          planName: 'Restoration Plan',
          patient: jane,
          doctorLabel: 'Dr. Reyes',
          items: items,
          requirements: const [PlanRequirement('Plan name', met: true)],
          isSubmitting: false,
          onSubmit: () => submitted++,
          onCancel: () {},
        ),
      );

      await tester.tap(find.text('Create Plan'));
      expect(submitted, 1);
    });
  });

  group('GrandTotalBar', () {
    testWidgets('shows pesos and the first unmet requirement', (tester) async {
      await pumpDarkHosted(
        tester,
        GrandTotalBar(
          total: 4500,
          itemCount: 3,
          isSubmitting: false,
          blockedReason: 'Missing: Doctor',
          onSubmit: () {},
        ),
      );

      expect(find.text('₱4,500.00'), findsOneWidget);
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.text('Grand total · 3 steps'), findsOneWidget);
      expect(find.text('Missing: Doctor'), findsOneWidget);
      expectReadableOnLightCard(textColor(tester, '₱4,500.00'), 'total');
    });

    testWidgets('submitting disables the button', (tester) async {
      var submitted = 0;

      await pumpDarkHosted(
        tester,
        GrandTotalBar(
          total: 0,
          itemCount: 1,
          isSubmitting: true,
          onSubmit: () => submitted++,
        ),
      );

      expect(find.text('Saving…'), findsOneWidget);
      await tester.tap(find.text('Saving…'), warnIfMissed: false);
      expect(submitted, 0);
    });
  });
}
