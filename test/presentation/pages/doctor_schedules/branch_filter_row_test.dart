// test/presentation/pages/doctor_schedules/branch_filter_row_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/core/errors/exceptions.dart';
import 'package:smile_concept_web/data/models/doctor_schedule/branch_option_model.dart';
import 'package:smile_concept_web/presentation/pages/doctor_schedules/widgets/branch_filter_row.dart';
import 'package:smile_concept_web/presentation/providers/doctor_schedule/schedule_form_providers.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';

void main() {
  const branches = [
    BranchOption(id: 1, name: 'Murcia Branch', branchCode: 'MUR-001'),
    BranchOption(id: 2, name: 'Fellisa Branch', branchCode: 'FEL-002'),
  ];

  /// Hosted under `ThemeData.dark()` because that is what `main.dart` still
  /// installs — the pills sit on a light card and must not inherit it.
  Future<void> pump(
    WidgetTester tester, {
    int? selected,
    ValueChanged<int?>? onChanged,
    Future<List<BranchOption>> Function()? load,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          branchesListProvider.overrideWith(
            (ref) => load == null ? Future.value(branches) : load(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: BranchFilterRow(
              selectedBranchId: selected,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists every branch plus an All Branches pill', (tester) async {
    await pump(tester);

    expect(find.text('All Branches'), findsOneWidget);
    expect(find.text('Murcia Branch'), findsOneWidget);
    expect(find.text('Fellisa Branch'), findsOneWidget);
  });

  testWidgets('selecting a branch reports its id', (tester) async {
    int? reported;
    var calls = 0;

    await pump(tester, onChanged: (v) {
      reported = v;
      calls++;
    });

    await tester.tap(find.text('Fellisa Branch'));

    expect(calls, 1);
    expect(reported, 2);
  });

  testWidgets('tapping the active branch clears it', (tester) async {
    int? reported = 999;

    await pump(tester, selected: 1, onChanged: (v) => reported = v);

    await tester.tap(find.text('Murcia Branch'));

    expect(reported, isNull);
  });

  testWidgets('All Branches clears the filter', (tester) async {
    int? reported = 999;

    await pump(tester, selected: 2, onChanged: (v) => reported = v);

    await tester.tap(find.text('All Branches'));

    expect(reported, isNull);
  });

  testWidgets('the selected pill reads white on its filled background',
      (tester) async {
    await pump(tester, selected: 1);

    final selected = tester.widget<Text>(find.text('Murcia Branch'));
    final unselected = tester.widget<Text>(find.text('Fellisa Branch'));

    expect(selected.style?.color, Colors.white);

    // The unselected pill sits on the light card, so it must stay dark —
    // inheriting the dark theme here is the bug this guards.
    final unselectedColor = unselected.style?.color;
    expect(unselectedColor, isNotNull);
    expect(unselectedColor!.computeLuminance(), lessThan(0.5));
  });

  testWidgets('long branch names are ellipsised, not overflowing',
      (tester) async {
    await pump(
      tester,
      load: () async => const [
        BranchOption(
          id: 3,
          name: 'Bacolod City Central Dental Annex Branch',
          branchCode: 'BAC-003',
        ),
      ],
    );

    final label = tester.widget<Text>(
      find.text('Bacolod City Central Dental Annex Branch'),
    );
    expect(label.overflow, TextOverflow.ellipsis);
    expect(label.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a loading line while branches resolve', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          branchesListProvider.overrideWith(
            (ref) => Future.delayed(
              const Duration(seconds: 1),
              () => branches,
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BranchFilterRow(selectedBranchId: null, onChanged: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading branches...'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('a 403 explains itself and offers no retry', (tester) async {
    await pump(
      tester,
      load: () async => throw const ApiException(
        message: 'This action is unauthorized.',
        code: 'SERVER_ERROR',
        statusCode: 403,
      ),
    );

    expect(find.textContaining('Not permitted (403)'), findsOneWidget);
    // Retrying an authorization refusal can only fail again.
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a server error offers a retry that refetches', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          branchesListProvider.overrideWith((ref) async {
            attempts++;
            if (attempts == 1) {
              throw const ApiException(
                message: 'Server error (500)',
                code: 'SERVER_ERROR',
                statusCode: 500,
              );
            }
            return branches;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BranchFilterRow(selectedBranchId: null, onChanged: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Murcia Branch'), findsOneWidget);
  });

  testWidgets('an empty branch list says so instead of rendering bare pills',
      (tester) async {
    await pump(tester, load: () async => const []);

    expect(find.text('No branches available'), findsOneWidget);
    expect(find.text('All Branches'), findsNothing);
  });
}
