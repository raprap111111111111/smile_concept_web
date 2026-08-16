// test/presentation/widgets/shared/item_picker_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/inventory/inventory_item_model.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/widgets/shared/item_picker_dialog.dart';

void main() {
  const catalog = [
    InventoryItemModel(
      id: 5,
      name: 'Lidocaine 2% carpule',
      sku: 'ANES-LIDO-2',
      category: 'Anesthetics',
      unitOfMeasure: 'carpule',
    ),
    InventoryItemModel(
      id: 9,
      name: 'Cotton roll',
      sku: 'CONS-COTTON',
      category: 'Consumables',
      unitOfMeasure: 'piece',
    ),
  ];

  /// Hosted under `ThemeData.dark()` — what main.dart boots. `showDialog`
  /// pushes onto the root navigator, so the picker gets this theme rather than
  /// any light theme its opener pinned. That is exactly the bug being guarded.
  Future<void> openPicker(
    WidgetTester tester, {
    List<InventoryItemModel> items = catalog,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<InventoryItemModel>(
                context: context,
                builder: (_) =>
                    ItemPickerDialog(items: items, title: 'Add supply'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders on a light surface inside a dark app', (tester) async {
    await openPicker(tester);

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor, AppColors.background);
    expect(dialog.backgroundColor!.computeLuminance(), greaterThan(0.8));
  });

  testWidgets('item text stays dark enough to read on that surface',
      (tester) async {
    await openPicker(tester);

    final name = tester.widget<Text>(find.text('Cotton roll')).style;
    expect(name?.color, isNotNull);
    expect(name!.color!.computeLuminance(), lessThan(0.5));

    final meta =
        tester.widget<Text>(find.text('CONS-COTTON  ·  Consumables')).style;
    expect(meta!.color!.computeLuminance(), lessThan(0.5));
  });

  testWidgets('searching narrows the list and reports a miss', (tester) async {
    await openPicker(tester);

    expect(find.text('2 items available'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'cotton');
    await tester.pumpAndSettle();

    expect(find.text('Cotton roll'), findsOneWidget);
    expect(find.text('Lidocaine 2% carpule'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('picking a row pops it back to the caller', (tester) async {
    await openPicker(tester);

    await tester.tap(find.text('Lidocaine 2% carpule'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('an exhausted catalog says so instead of showing blank',
      (tester) async {
    await openPicker(tester, items: const []);

    expect(find.text('Nothing left to add'), findsOneWidget);
  });
}
