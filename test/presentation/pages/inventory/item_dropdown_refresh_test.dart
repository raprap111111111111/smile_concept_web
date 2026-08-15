// test/presentation/pages/inventory/item_dropdown_refresh_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/inventory/inventory_item_model.dart';
import 'package:smile_concept_web/presentation/pages/inventory/widgets/item_dropdown.dart';
import 'package:smile_concept_web/presentation/providers/inventory/inventory_form_providers.dart';

/// The picker lists were plain FutureProviders: resolved once, cached for the
/// whole session. A form opened while the catalog was still empty kept saying
/// "No items available. Please add items to the catalog first." forever, no
/// matter how many items were added afterwards.
///
/// autoDispose is what fixes it, and it is invisible in a diff — hence a test.
void main() {
  const gloves = InventoryItemModel(
    id: 1,
    name: 'Latex Gloves',
    sku: '123552',
    category: 'Restorative',
    unitOfMeasure: 'tube',
    minimumThreshold: 10,
  );

  Widget host({required bool showDropdown}) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: showDropdown
            ? ItemDropdown(value: null, onChanged: (_) {})
            : const Text('somewhere else'),
      ),
    );
  }

  testWidgets('an empty catalog is not cached for the rest of the session',
      (tester) async {
    var calls = 0;
    var catalogIsEmpty = true;

    Widget app({required bool showDropdown}) {
      return ProviderScope(
        overrides: [
          itemsSimpleListProvider.overrideWith((ref) async {
            calls++;
            return catalogIsEmpty
                ? <InventoryItemModel>[]
                : <InventoryItemModel>[gloves];
          }),
        ],
        child: host(showDropdown: showDropdown),
      );
    }

    // 1. Open a form while the catalog is still empty.
    await tester.pumpWidget(app(showDropdown: true));
    await tester.pumpAndSettle();

    expect(find.textContaining('No items available'), findsOneWidget);
    expect(calls, 1);

    // 2. Navigate away, add an item elsewhere, come back.
    await tester.pumpWidget(app(showDropdown: false));
    await tester.pumpAndSettle();

    catalogIsEmpty = false;

    await tester.pumpWidget(app(showDropdown: true));
    await tester.pumpAndSettle();

    // Without autoDispose the provider would still be holding the empty list
    // and calls would stay at 1.
    expect(calls, 2, reason: 'the picker must refetch, not serve a stale list');
    expect(find.textContaining('No items available'), findsNothing);

    // A dropdown only paints its option labels once opened, so the presence of
    // the field — rather than the item's text — is what says the list arrived.
    expect(
      find.byWidgetPredicate((w) => w is DropdownButtonFormField),
      findsOneWidget,
    );
  });

  testWidgets('the empty state still shows when the catalog is genuinely empty',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsSimpleListProvider
              .overrideWith((ref) async => <InventoryItemModel>[]),
        ],
        child: host(showDropdown: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No items available'), findsOneWidget);
  });
}
