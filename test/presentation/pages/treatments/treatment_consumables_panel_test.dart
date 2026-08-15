// test/presentation/pages/treatments/treatment_consumables_panel_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/inventory/inventory_item_model.dart';
import 'package:smile_concept_web/data/models/inventory/treatment_consumable_model.dart';
import 'package:smile_concept_web/presentation/pages/treatments/widgets/treatment_consumables_panel.dart';
import 'package:smile_concept_web/presentation/providers/inventory/inventory_form_providers.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';

/// The recipe panel is what turns "we should track supplies" into a number the
/// deduction path can act on, so its edit semantics are worth pinning down.
void main() {
  const anesthetic = InventoryItemModel(
    id: 1,
    name: 'Lidocaine 2% carpule',
    sku: 'ANES-LIDO-2',
    category: 'Anesthetics',
    unitOfMeasure: 'carpule',
    minimumThreshold: 20,
  );

  const cottonRoll = InventoryItemModel(
    id: 2,
    name: 'Cotton roll',
    sku: 'CON-COT-1',
    category: 'Hygiene',
    unitOfMeasure: 'piece',
    minimumThreshold: 50,
  );

  Future<List<TreatmentConsumableModel>?> pump(
    WidgetTester tester, {
    required List<TreatmentConsumableModel> initial,
    List<InventoryItemModel> items = const [anesthetic, cottonRoll],
  }) async {
    List<TreatmentConsumableModel>? reported;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsSimpleListProvider.overrideWith((ref) => Future.value(items)),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              child: TreatmentConsumablesPanel(
                consumables: initial,
                onChanged: (lines) => reported = lines,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return reported;
  }

  testWidgets('an empty recipe explains what that means', (tester) async {
    await pump(tester, initial: const []);

    expect(
      find.textContaining('will not draw anything from stock'),
      findsOneWidget,
    );
  });

  testWidgets('existing lines render with their item and unit', (tester) async {
    await pump(tester, initial: const [
      TreatmentConsumableModel(
        itemId: 1,
        quantityPerUse: 2,
        item: anesthetic,
      ),
    ]);

    expect(find.text('Lidocaine 2% carpule'), findsOneWidget);
    expect(find.text('ANES-LIDO-2'), findsOneWidget);
    // The unit sits under the quantity box so "2" reads as 2 carpules.
    expect(find.text('carpule'), findsOneWidget);
  });

  testWidgets('changing the quantity reports the new figure', (tester) async {
    List<TreatmentConsumableModel>? reported;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsSimpleListProvider
              .overrideWith((ref) => Future.value([anesthetic])),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TreatmentConsumablesPanel(
                consumables: const [
                  TreatmentConsumableModel(
                    itemId: 1,
                    quantityPerUse: 2,
                    item: anesthetic,
                  ),
                ],
                onChanged: (lines) => reported = lines,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '5');
    await tester.pump();

    expect(reported, isNotNull);
    expect(reported!.single.quantityPerUse, 5);
  });

  testWidgets('a zero quantity is ignored rather than reported', (tester) async {
    List<TreatmentConsumableModel>? reported;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsSimpleListProvider
              .overrideWith((ref) => Future.value([anesthetic])),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TreatmentConsumablesPanel(
                consumables: const [
                  TreatmentConsumableModel(
                    itemId: 1,
                    quantityPerUse: 2,
                    item: anesthetic,
                  ),
                ],
                onChanged: (lines) => reported = lines,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The server rejects min:0 anyway; not reporting it keeps the form from
    // holding a value that can only fail on save.
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.pump();

    expect(reported, isNull);
  });

  testWidgets('removing a line drops it from the reported list',
      (tester) async {
    List<TreatmentConsumableModel>? reported;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsSimpleListProvider.overrideWith(
            (ref) => Future.value([anesthetic, cottonRoll]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TreatmentConsumablesPanel(
                consumables: const [
                  TreatmentConsumableModel(
                      itemId: 1, quantityPerUse: 2, item: anesthetic),
                  TreatmentConsumableModel(
                      itemId: 2, quantityPerUse: 5, item: cottonRoll),
                ],
                onChanged: (lines) => reported = lines,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove').first);
    await tester.pump();

    expect(reported, isNotNull);
    expect(reported!.length, 1);
    expect(reported!.single.itemId, 2);
  });

  testWidgets('an item already on the list cannot be added twice',
      (tester) async {
    // The table has unique(treatment_id, item_id); filtering here means the
    // user never reaches the validation error at all.
    await pump(
      tester,
      initial: const [
        TreatmentConsumableModel(itemId: 1, quantityPerUse: 2, item: anesthetic),
        TreatmentConsumableModel(itemId: 2, quantityPerUse: 5, item: cottonRoll),
      ],
    );

    expect(find.text('All items added'), findsOneWidget);

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('adding picks from a searchable dialog', (tester) async {
    List<TreatmentConsumableModel>? reported;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsSimpleListProvider.overrideWith(
            (ref) => Future.value([anesthetic, cottonRoll]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TreatmentConsumablesPanel(
                consumables: const [],
                onChanged: (lines) => reported = lines,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add consumable'));
    await tester.pumpAndSettle();

    // A dropdown would bury anything past the fold once a catalog runs long.
    await tester.enterText(find.byType(TextField), 'cotton');
    await tester.pumpAndSettle();

    expect(find.text('Lidocaine 2% carpule'), findsNothing);

    await tester.tap(find.text('Cotton roll'));
    await tester.pumpAndSettle();

    expect(reported, isNotNull);
    expect(reported!.single.itemId, 2);
    expect(reported!.single.quantityPerUse, 1, reason: 'new lines start at 1');
  });
}
