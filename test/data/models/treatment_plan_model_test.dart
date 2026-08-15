// test/data/models/treatment_plan_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/treatment/treatment_model.dart';
import 'package:smile_concept_web/data/models/treatment/treatment_plan_model.dart';

class _StubTreatment extends TreatmentModel {
  const _StubTreatment() : super(id: 7, name: 'Deep Cleaning', price: 1500);
}

/// The payloads below are the shapes `TreatmentPlanResource::toArray` actually
/// emits. The model used to read `items`, which that resource never sends, so
/// every plan arrived with zero steps and the card reported "0 treatment steps"
/// no matter what was saved.
void main() {
  Map<String, dynamic> resourcePayload() => {
        'id': 12,
        'name': 'Full Upper Arch Restoration',
        'status': 'proposed',
        'status_label': 'Proposed',
        'total_estimated_amount': '4500.00',
        'notes': 'Start after the extraction heals.',
        'patient': {'id': 31, 'name': 'Jane Cruz'},
        'doctor': {'id': 4, 'name': 'Dr. Reyes'},
        'steps': [
          {
            'id': 90,
            'sequence_order': 2,
            'treatment_id': 7,
            'treatment_name': 'Deep Cleaning',
            'estimated_cost': '1500.00',
            'notes': null,
          },
          {
            'id': 89,
            'sequence_order': 1,
            'treatment_id': 5,
            'treatment_name': 'Composite Filling',
            'estimated_cost': '3000.00',
            'notes': 'Upper left molar',
          },
        ],
        'created_at': '2026-08-14T09:00:00.000000Z',
        'updated_at': '2026-08-14T09:00:00.000000Z',
      };

  group('TreatmentPlanModel.fromJson', () {
    test('reads the steps the API actually sends', () {
      final plan = TreatmentPlanModel.fromJson(resourcePayload());

      expect(plan.items, hasLength(2));
      expect(plan.hasItems, isTrue);
      expect(plan.formattedTotal, '₱4,500.00');
    });

    test('orders steps by sequence, not by payload order', () {
      final plan = TreatmentPlanModel.fromJson(resourcePayload());

      expect(
        plan.items.map((i) => i.sequenceOrder).toList(),
        [1, 2],
      );
      expect(plan.items.first.treatmentName, 'Composite Filling');
      expect(plan.items.last.treatmentName, 'Deep Cleaning');
    });

    test('falls back to the nested relations for the foreign keys', () {
      // The resource omits user_id / doctor_id entirely; they used to land as 0.
      final plan = TreatmentPlanModel.fromJson(resourcePayload());

      expect(plan.userId, 31);
      expect(plan.doctorId, 4);
      expect(plan.patient?.name, 'Jane Cruz');
      expect(plan.doctor?.name, 'Dr. Reyes');
    });

    test('still reads the eager-loaded `items` shape', () {
      final plan = TreatmentPlanModel.fromJson({
        'id': 1,
        'user_id': 31,
        'doctor_id': 4,
        'name': 'Legacy shape',
        'status': 'accepted',
        'total_estimated_amount': 1500,
        'items': [
          {
            'id': 90,
            'treatment_plan_id': 1,
            'treatment_id': 7,
            'sequence_order': 1,
            'estimated_cost': 1500,
            'treatment': {
              'id': 7,
              'name': 'Deep Cleaning',
              'price': 1500,
              'estimated_duration_minutes': 45,
            },
          },
        ],
      });

      expect(plan.items, hasLength(1));
      expect(plan.items.single.treatmentName, 'Deep Cleaning');
      expect(plan.userId, 31);
      expect(plan.doctorId, 4);
    });

    test('a plan with no steps stays empty rather than throwing', () {
      final payload = resourcePayload()..['steps'] = <dynamic>[];
      final plan = TreatmentPlanModel.fromJson(payload);

      expect(plan.items, isEmpty);
      expect(plan.hasItems, isFalse);
    });
  });

  group('TreatmentPlanItemModel quantity', () {
    test('reads quantity and the frozen unit price', () {
      final item = TreatmentPlanItemModel.fromJson({
        'id': 1,
        'treatment_id': 7,
        'sequence_order': 1,
        'quantity': 3,
        'unit_price': '1500.00',
        'estimated_cost': '4500.00',
      });

      expect(item.quantity, 3);
      expect(item.unitPrice, 1500);
      expect(item.estimatedCost, 4500);
      expect(item.quantityLabel, '₱1,500.00 × 3');
    });

    test('rows written before quantity existed read as a single unit', () {
      final item = TreatmentPlanItemModel.fromJson({
        'id': 1,
        'treatment_id': 7,
        'sequence_order': 1,
        'estimated_cost': '1500.00',
      });

      expect(item.quantity, 1);
      expect(item.unitPrice, 1500);
      expect(item.estimatedCost, 1500);
    });

    test('a zero or missing quantity never divides by zero', () {
      final item = TreatmentPlanItemModel.fromJson({
        'id': 1,
        'treatment_id': 7,
        'sequence_order': 1,
        'quantity': 0,
        'estimated_cost': '1500.00',
      });

      expect(item.quantity, 1);
      expect(item.unitPrice, 1500);
    });
  });

  group('TreatmentPlanItemForm.toPayload', () {
    test('sends quantity and leaves pricing to the server', () {
      final form = TreatmentPlanItemForm()..quantity = 3;
      addTearDown(form.dispose);
      form.selectedTreatment = const _StubTreatment();
      form.notesController.text = '  Upper left molar  ';

      final payload = form.toPayload(2);

      expect(payload, {
        'sequence_order': 2,
        'treatment_id': 7,
        'quantity': 3,
        'notes': 'Upper left molar',
      });
      // The API prices from the catalog; a client price would be ignored at
      // best and a way to under-quote at worst.
      expect(payload.containsKey('price'), isFalse);
    });

    test('omits empty notes entirely', () {
      final form = TreatmentPlanItemForm();
      addTearDown(form.dispose);
      form.selectedTreatment = const _StubTreatment();

      final payload = form.toPayload(1);

      expect(payload.containsKey('notes'), isFalse);
      expect(payload['quantity'], 1);
    });
  });

  group('TreatmentPlanItemModel', () {
    test('names an unresolvable treatment instead of rendering blank', () {
      final item = TreatmentPlanItemModel.fromJson({
        'id': 1,
        'treatment_id': 7,
        'sequence_order': 1,
        'estimated_cost': '0',
      });

      expect(item.treatmentName, 'Treatment #7');
      expect(item.hasNotes, isFalse);
      expect(item.formattedCost, '₱0.00');
    });
  });
}
