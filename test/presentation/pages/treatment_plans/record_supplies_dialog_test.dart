// test/presentation/pages/treatment_plans/record_supplies_dialog_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/core/network/dio_client.dart';
import 'package:smile_concept_web/data/models/inventory/inventory_branch_model.dart';
import 'package:smile_concept_web/data/models/inventory/inventory_item_model.dart';
import 'package:smile_concept_web/data/models/treatment/treatment_plan_model.dart';
import 'package:smile_concept_web/presentation/pages/treatment_plans/widgets/record_supplies_dialog.dart';
import 'package:smile_concept_web/presentation/providers/inventory/inventory_form_providers.dart';

class _StubAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Map<String, dynamic> getBody;
  Map<String, dynamic> postBody;

  _StubAdapter({required this.getBody, required this.postBody});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final isPost = options.method == 'POST';

    return ResponseBody.fromString(
      jsonEncode(isPost ? postBody : getBody),
      isPost ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> suggestionsBody() => {
      'data': {
        'recorded': false,
        'movements': <dynamic>[],
        'suggested_lines': [
          {
            'item_id': 5,
            'name': 'Lidocaine 2% carpule',
            'sku': 'ANES-LIDO-2',
            'unit_of_measure': 'carpule',
            'is_optional': false,
            'suggested_quantity': 6,
          },
          {
            'item_id': 9,
            'name': 'Cotton roll',
            'sku': 'CONS-COTTON',
            'unit_of_measure': 'piece',
            'is_optional': true,
            'suggested_quantity': 12,
          },
        ],
      },
    };

Map<String, dynamic> recordedBody() => {
      'data': {
        'recorded': true,
        'movements': [
          {
            'id': 41,
            'branch_id': 1,
            'item_id': 5,
            'type': 'consumption',
            'type_label': 'Used in treatment',
            'quantity_delta': -6,
            'balance_after': 44,
            'item': {'id': 5, 'name': 'Lidocaine 2% carpule'},
          },
        ],
        'suggested_lines': <dynamic>[],
      },
    };

Map<String, dynamic> postResultBody() => {
      'data': {
        'recorded': true,
        'movements': <dynamic>[],
        'shortfalls': <dynamic>[],
      },
    };

TreatmentPlanModel plan() => TreatmentPlanModel.fromJson({
      'id': 7,
      'name': 'Molar rescue mission',
      'status': 'completed',
      'total_estimated_amount': '4000.00',
      'patient': {'id': 31, 'name': 'Jane Cruz'},
      'doctor': {'id': 4, 'name': 'Dr. Reyes'},
      'steps': <dynamic>[],
    });

Widget wrap(_StubAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;

  return ProviderScope(
    overrides: [
      dioProvider.overrideWithValue(dio),
      branchesSimpleListProvider.overrideWith(
        (ref) async => const [
          InventoryBranchModel(id: 1, name: 'Main', branchCode: 'MAIN'),
        ],
      ),
      itemsSimpleListProvider.overrideWith(
        (ref) async => const [
          InventoryItemModel(id: 5, name: 'Lidocaine 2% carpule'),
          InventoryItemModel(id: 9, name: 'Cotton roll'),
          InventoryItemModel(id: 12, name: 'Suture pack'),
        ],
      ),
    ],
    // Hosted under the dark theme main.dart boots, so the dialog's own
    // light-theme pin is exercised rather than bypassed.
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => RecordSuppliesDialog.show(context, plan()),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> openDialog(WidgetTester tester, _StubAdapter adapter) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrap(adapter));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('prefills the recipe suggestions and warns about appointments',
      (tester) async {
    final adapter = _StubAdapter(
      getBody: suggestionsBody(),
      postBody: postResultBody(),
    );

    await openDialog(tester, adapter);

    expect(find.text('Record supplies used'), findsOneWidget);
    expect(find.textContaining('deducts again'), findsOneWidget);

    expect(find.text('Lidocaine 2% carpule'), findsOneWidget);
    expect(find.text('Cotton roll'), findsOneWidget);
    expect(find.text('Optional in the recipe'), findsOneWidget);

    // Suggested quantities, prefilled into the editable fields.
    expect(find.widgetWithText(TextFormField, '6'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '12'), findsOneWidget);
  });

  testWidgets('posts the edited lines, not the suggested ones', (tester) async {
    final adapter = _StubAdapter(
      getBody: suggestionsBody(),
      postBody: postResultBody(),
    );

    await openDialog(tester, adapter);

    // Pick the branch these supplies came from.
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main (MAIN)').last);
    await tester.pumpAndSettle();

    // Correct the anesthetic down, drop the optional cotton entirely. The
    // dialog scrolls internally, so each target is brought into view first —
    // a tap on an off-screen row lands on whatever is at those coordinates.
    await tester.ensureVisible(find.widgetWithText(TextFormField, '6'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '6'), '4');
    await tester.pump();

    await tester.ensureVisible(find.byTooltip('Remove').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove').last);
    await tester.pumpAndSettle();

    expect(find.text('Cotton roll'), findsNothing);

    await tester.tap(find.text('Record supplies'));
    await tester.pumpAndSettle();

    final post = adapter.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/treatment-plans/7/consumables');

    final body = post.data as Map<String, dynamic>;
    expect(body['branch_id'], 1);
    expect(body['lines'], [
      {'item_id': 5, 'quantity': 4},
    ]);
  });

  testWidgets('an already-recorded plan is read-only', (tester) async {
    final adapter = _StubAdapter(
      getBody: recordedBody(),
      postBody: postResultBody(),
    );

    await openDialog(tester, adapter);

    expect(find.textContaining('already recorded'), findsOneWidget);
    expect(find.text('Record supplies'), findsNothing);
    expect(find.text('Lidocaine 2% carpule'), findsOneWidget);
    expect(find.text('-6'), findsOneWidget);
  });
}
