// test/presentation/pages/inventory/inventory_form_readability_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/inventory/inventory_branch_model.dart';
import 'package:smile_concept_web/data/models/inventory/inventory_item_model.dart';
import 'package:smile_concept_web/presentation/pages/inventory/item_form_page.dart';
import 'package:smile_concept_web/presentation/pages/inventory/stock_action_page.dart';
import 'package:smile_concept_web/presentation/providers/inventory/inventory_form_providers.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';

/// `main.dart` runs `ThemeData.dark()`, but the items and inventory forms
/// paint light `AppColors` surfaces. Before these pages pinned
/// [AppTheme.lightTheme] around their scaffolds, every label, border and
/// dropdown menu took its colour from the ambient dark theme and rendered
/// near-white on white — or a dark menu behind dark ink text.
///
/// Each page here is hosted under the real dark theme, so a regression
/// reproduces the production bug rather than a lab-clean default.
void main() {
  Widget darkHosted(Widget page, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: page,
      ),
    );
  }

  double luminanceOf(Color? color) {
    expect(color, isNotNull, reason: 'colour was inherited, not set');
    return color!.computeLuminance();
  }

  /// The colour the text actually paints with — labels and hints take theirs
  /// from the ambient theme via DefaultTextStyle, so the Text widget's own
  /// style is null and only the render object knows the truth.
  Color? renderedColorOf(WidgetTester tester, Finder textFinder) {
    return tester.renderObject<RenderParagraph>(textFinder).text.style?.color;
  }

  /// The colour the opened dropdown paints its panel with. The panel is drawn
  /// by a private painter, not a Material — it reads `dropdownColor ??
  /// canvasColor` from the theme captured into the overlay, which is exactly
  /// what resolves at the menu item's own element.
  Color menuCanvasBehind(WidgetTester tester, Finder itemText) {
    return Theme.of(tester.element(itemText)).canvasColor;
  }

  void expectReadableOnLight(Color? color, String what) {
    final lum = luminanceOf(color);
    expect(
      lum,
      lessThan(0.5),
      reason: '$what has luminance $lum — too light to read on the light card',
    );
  }

  void expectLightSurface(Color? color, String what) {
    final lum = luminanceOf(color);
    expect(
      lum,
      greaterThan(0.5),
      reason: '$what has luminance $lum — a dark surface under light-designed '
          'content',
    );
  }

  group('ItemFormPage', () {
    testWidgets('field labels stay readable under the dark app theme',
        (tester) async {
      await tester.pumpWidget(darkHosted(const ItemFormPage()));
      await tester.pumpAndSettle();

      for (final label in ['Item Name *', 'SKU *', 'Category *']) {
        expectReadableOnLight(
          renderedColorOf(tester, find.text(label)),
          '"$label" label',
        );
      }
    });

    testWidgets('form subtree resolves the light input theme', (tester) async {
      await tester.pumpWidget(darkHosted(const ItemFormPage()));
      await tester.pumpAndSettle();

      final theme = Theme.of(
        tester.element(find.byType(TextFormField).first),
      );
      expect(theme.brightness, Brightness.light);
      expect(theme.inputDecorationTheme.fillColor, AppColors.surface);
    });

    testWidgets('the category dropdown opens a light menu with readable items',
        (tester) async {
      await tester.pumpWidget(darkHosted(const ItemFormPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select category'));
      await tester.pumpAndSettle();

      // The open menu draws on the theme's canvas colour; under the ambient
      // dark theme that was a near-black panel behind ink-dark item text.
      expectLightSurface(
        menuCanvasBehind(tester, find.text('PPE').last),
        'dropdown menu panel',
      );

      expectReadableOnLight(
        renderedColorOf(tester, find.text('PPE').last),
        'dropdown menu item',
      );
    });
  });

  group('StockActionPage', () {
    const branches = [
      InventoryBranchModel(id: 1, name: 'Main Clinic', branchCode: 'MAIN'),
    ];
    const items = [
      InventoryItemModel(
        id: 1,
        name: 'Latex Gloves',
        sku: 'LG-200',
        category: 'PPE',
        unitOfMeasure: 'box',
        minimumThreshold: 10,
      ),
    ];

    testWidgets('dropdown fields and labels stay readable under the dark theme',
        (tester) async {
      await tester.pumpWidget(
        darkHosted(
          const StockActionPage(action: StockAction.stockIn),
          overrides: [
            branchesSimpleListProvider.overrideWith((ref) async => branches),
            itemsSimpleListProvider.overrideWith((ref) async => items),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expectReadableOnLight(
        renderedColorOf(tester, find.text('Branch *')),
        'branch dropdown label',
      );
      expectReadableOnLight(
        renderedColorOf(tester, find.text('Item *')),
        'item dropdown label',
      );

      final theme = Theme.of(
        tester.element(find.byType(TextFormField).first),
      );
      expect(theme.brightness, Brightness.light);
      expect(theme.inputDecorationTheme.fillColor, AppColors.surface);
    });

    testWidgets('the branch dropdown opens a light menu', (tester) async {
      await tester.pumpWidget(
        darkHosted(
          const StockActionPage(action: StockAction.stockIn),
          overrides: [
            branchesSimpleListProvider.overrideWith((ref) async => branches),
            itemsSimpleListProvider.overrideWith((ref) async => items),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select a branch'));
      await tester.pumpAndSettle();

      expectLightSurface(
        menuCanvasBehind(tester, find.text('Main Clinic (MAIN)').last),
        'branch menu panel',
      );
    });
  });
}
