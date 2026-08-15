import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/core/utils/toast_helper.dart';

void main() {
  Widget harness(void Function(BuildContext) onTap) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onTap(context),
            child: const Text('fire'),
          ),
        ),
      ),
    );
  }

  for (final entry in <String, void Function(BuildContext, String)>{
    'success': ToastHelper.success,
    'error': ToastHelper.error,
    'warning': ToastHelper.warning,
    'info': ToastHelper.info,
  }.entries) {
    testWidgets('${entry.key} toast auto-dismisses without user interaction', (
      tester,
    ) async {
      await tester.pumpWidget(harness((c) => entry.value(c, 'hello there')));

      await tester.tap(find.text('fire'));
      await tester.pumpAndSettle();
      expect(find.text('hello there'), findsOneWidget);

      // The dismiss timer is only armed once the entrance animation completes.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('hello there'), findsNothing);
    });
  }

  testWidgets('toast still offers a manual dismiss control', (tester) async {
    await tester.pumpWidget(harness((c) => ToastHelper.info(c, 'manual')));

    await tester.tap(find.text('fire'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('manual'), findsNothing);
  });
}
