// test/data/models/inventory/stock_models_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/inventory/inventory_batch_model.dart';
import 'package:smile_concept_web/data/models/inventory/stock_movement_model.dart';

/// These two models decide the words a user reads on the detail page, so the
/// phrasing rules are worth pinning rather than eyeballing.
void main() {
  String isoDaysFromNow(int days) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return midnight.add(Duration(days: days)).toIso8601String().split('T').first;
  }

  InventoryBatchModel batch({
    String? expiry,
    String? lot,
    int remaining = 10,
    String unit = 'carpule',
  }) {
    return InventoryBatchModel.fromJson({
      'id': 1,
      'branch_id': 1,
      'item_id': 1,
      'lot_number': lot,
      'expiry_date': expiry,
      'quantity_received': 20,
      'quantity_remaining': remaining,
      'received_at': '2026-01-01',
      'is_expired': false,
      'item': {'id': 1, 'name': 'Lidocaine', 'unit_of_measure': unit},
    });
  }

  group('InventoryBatchModel', () {
    test('a missing expiry reads as non-perishable, not as a blank', () {
      expect(batch(expiry: null).expiryLabel, 'No expiry');
    });

    test('a past expiry says so plainly', () {
      expect(batch(expiry: isoDaysFromNow(-5)).expiryLabel, 'Expired');
    });

    test('today and tomorrow are named, not counted', () {
      expect(batch(expiry: isoDaysFromNow(0)).expiryLabel, 'Expires today');
      expect(batch(expiry: isoDaysFromNow(1)).expiryLabel, 'Expires tomorrow');
    });

    test('near dates count down in days', () {
      // A reader should never have to subtract dates to know a lot is a
      // problem.
      expect(batch(expiry: isoDaysFromNow(12)).expiryLabel, 'Expires in 12 days');
    });

    test('distant dates fall back to a calendar date', () {
      final label = batch(expiry: isoDaysFromNow(400)).expiryLabel;

      expect(label, startsWith('Expires '));
      expect(label, isNot(contains('days')));
    });

    test('isExpiringWithin excludes already-expired lots', () {
      // Expired is a different, more urgent state — the detail page shows it
      // with its own colour and icon.
      expect(batch(expiry: isoDaysFromNow(-1)).isExpiringWithin(30), isFalse);
      expect(batch(expiry: isoDaysFromNow(10)).isExpiringWithin(30), isTrue);
      expect(batch(expiry: isoDaysFromNow(40)).isExpiringWithin(30), isFalse);
    });

    test('a missing lot number is labelled rather than left empty', () {
      expect(batch(lot: null).lotLabel, 'No lot number');
      expect(batch(lot: 'A1').lotLabel, 'Lot A1');
    });

    test('amounts pluralise against the item unit', () {
      expect(batch(remaining: 1).amountLabel, '1 carpule');
      expect(batch(remaining: 4).amountLabel, '4 carpules');
    });
  });

  group('StockMovementModel', () {
    StockMovementModel movement(Map<String, dynamic> overrides) {
      return StockMovementModel.fromJson({
        'id': 1,
        'branch_id': 1,
        'item_id': 1,
        'type': 'consumption',
        'type_label': 'Used in treatment',
        'quantity_delta': -2,
        'balance_after': 8,
        'is_shortfall': false,
        ...overrides,
      });
    }

    test('deltas always carry their sign', () {
      // A ledger column only reads as a statement if inflows are visibly
      // positive.
      expect(movement({'quantity_delta': 5}).deltaLabel, '+5');
      expect(movement({'quantity_delta': -5}).deltaLabel, '-5');
    });

    test('a person is credited when there is one', () {
      final row = movement({
        'performed_by': {'id': 3, 'name': 'Rina'},
      });

      expect(row.actorLabel, 'Rina');
    });

    test('automatic deduction is credited to the appointment, not a person', () {
      final row = movement({
        'reference_type': 'Appointment',
        'reference_id': 42,
      });

      expect(row.actorLabel, 'Automatic');
    });

    test('a shortfall is distinguishable from an ordinary withdrawal', () {
      expect(movement({'is_shortfall': true}).isShortfall, isTrue);
      expect(movement({}).isShortfall, isFalse);
    });

    test('the batch lot is lifted out of the nested payload', () {
      final row = movement({
        'batch': {'id': 7, 'lot_number': 'A1', 'expiry_date': '2027-01-01'},
      });

      expect(row.lotNumber, 'A1');
    });

    test('a null batch does not crash the row', () {
      expect(movement({'batch': null}).lotNumber, isNull);
    });
  });
}
