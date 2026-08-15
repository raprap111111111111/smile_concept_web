// test/presentation/pages/treatment_plans/treatment_plan_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/treatment/treatment_plan_model.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/treatment_plan_card.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';

void main() {
  /// Hosted under `ThemeData.dark()` — what main.dart boots — on the white card
  /// colour the list actually paints.
  Future<void> pumpCard(WidgetTester tester, TreatmentPlanModel plan) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Material(
            color: AppColors.background,
            child: SingleChildScrollView(
              child: TreatmentPlanCard(
                plan: plan,
                canDelete: false,
                canChangeStatus: false,
                onDelete: () {},
                onChangeStatus: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  TreatmentPlanModel planWithTwoSteps() => TreatmentPlanModel.fromJson({
        'id': 12,
        'name': 'Full Upper Arch Restoration',
        'status': 'proposed',
        'total_estimated_amount': '4500.00',
        'patient': {'id': 31, 'name': 'Jane Cruz'},
        'doctor': {'id': 4, 'name': 'Dr. Reyes'},
        'steps': [
          {
            'id': 89,
            'sequence_order': 1,
            'treatment_id': 5,
            'treatment_name': 'Composite Filling',
            'estimated_cost': '3000.00',
            'notes': 'Upper left molar',
          },
          {
            'id': 90,
            'sequence_order': 2,
            'treatment_id': 7,
            'treatment_name': 'Deep Cleaning',
            'estimated_cost': '1500.00',
          },
        ],
      });

  testWidgets('lists the saved treatment steps, not just a count',
      (tester) async {
    await pumpCard(tester, planWithTwoSteps());

    expect(find.text('2 treatment steps'), findsOneWidget);
    expect(find.text('Composite Filling'), findsOneWidget);
    expect(find.text('Deep Cleaning'), findsOneWidget);
    expect(find.text('Upper left molar'), findsOneWidget);

    // Sequence badges, in order.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('shows pesos, never dollars', (tester) async {
    await pumpCard(tester, planWithTwoSteps());

    expect(find.textContaining(r'$'), findsNothing);
    expect(find.text('₱4,500.00'), findsOneWidget);
    expect(find.text('₱3,000.00'), findsOneWidget);
    expect(find.text('₱1,500.00'), findsOneWidget);
  });

  testWidgets('step text stays readable on the white card', (tester) async {
    await pumpCard(tester, planWithTwoSteps());

    final style = tester.widget<Text>(find.text('Deep Cleaning')).style;
    expect(style?.color, isNotNull);
    expect(style!.color!.computeLuminance(), lessThan(0.5));
  });

  testWidgets('a multi-unit step shows the unit price and count',
      (tester) async {
    await pumpCard(
      tester,
      TreatmentPlanModel.fromJson({
        'id': 14,
        'name': 'Three fillings',
        'status': 'proposed',
        'total_estimated_amount': '4500.00',
        'patient': {'id': 31, 'name': 'Jane Cruz'},
        'doctor': {'id': 4, 'name': 'Dr. Reyes'},
        'steps': [
          {
            'id': 91,
            'sequence_order': 1,
            'treatment_id': 5,
            'treatment_name': 'Composite Filling',
            'quantity': 3,
            'unit_price': '1500.00',
            'estimated_cost': '4500.00',
          },
        ],
      }),
    );

    expect(find.text('₱1,500.00 × 3'), findsOneWidget);
    // Line total, not the unit price.
    expect(find.text('₱4,500.00'), findsNWidgets(2));
  });

  testWidgets('a single-unit step does not clutter with "× 1"', (tester) async {
    await pumpCard(tester, planWithTwoSteps());

    expect(find.textContaining('×'), findsNothing);
  });

  testWidgets('a plan with no steps omits the list', (tester) async {
    await pumpCard(
      tester,
      TreatmentPlanModel.fromJson({
        'id': 13,
        'name': 'Empty plan',
        'status': 'draft',
        'total_estimated_amount': 0,
        'patient': {'id': 31, 'name': 'Jane Cruz'},
        'doctor': {'id': 4, 'name': 'Dr. Reyes'},
        'steps': <dynamic>[],
      }),
    );

    expect(find.text('0 treatment steps'), findsOneWidget);
    expect(find.text('₱0.00'), findsOneWidget);
  });
}
