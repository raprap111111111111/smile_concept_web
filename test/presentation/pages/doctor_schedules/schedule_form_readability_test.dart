// test/presentation/pages/doctor_schedules/schedule_form_readability_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/presentation/pages/doctor_schedules/widgets/days_checkbox_list.dart';
import 'package:smile_concept_web/presentation/pages/doctor_schedules/widgets/dropdown_states.dart';
import 'package:smile_concept_web/presentation/pages/doctor_schedules/widgets/time_picker_field.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';

/// `main.dart` runs `ThemeData.dark()`, but the schedule form paints light
/// `AppColors` cards. Anything that takes its colour from the ambient theme
/// therefore renders near-white on white and disappears. Every widget below is
/// hosted under the real dark theme so a regression reproduces the actual bug
/// rather than a lab-clean default.
void main() {
  Future<void> pumpDarkHosted(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          // The colour the form's cards actually are.
          backgroundColor: AppColors.background,
          body: Material(child: child),
        ),
      ),
    );
  }

  /// Luminance of the light card. Foreground text must land clearly below it.
  double luminanceOf(Color? color) {
    expect(color, isNotNull, reason: 'colour was inherited, not set');
    return color!.computeLuminance();
  }

  void expectReadableOnLightCard(Color? color, String what) {
    final lum = luminanceOf(color);
    expect(
      lum,
      lessThan(0.5),
      reason: '$what has luminance $lum — too light to read on the '
          '${AppColors.background} card',
    );
  }

  group('TimePickerField', () {
    testWidgets('entered time stays dark on the light card', (tester) async {
      final controller = TextEditingController(text: '09:00:00');
      addTearDown(controller.dispose);

      await pumpDarkHosted(
        tester,
        TimePickerField(
          controller: controller,
          label: 'Start Time',
          icon: Icons.play_arrow_rounded,
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expectReadableOnLightCard(editable.style.color, 'time field text');
    });
  });

  group('DaysCheckboxList', () {
    testWidgets('section label and day rows stay readable', (tester) async {
      await pumpDarkHosted(
        tester,
        DaysCheckboxList(selectedDays: const {1}, onChanged: (_) {}),
      );

      expectReadableOnLightCard(
        tester.widget<Text>(find.text('Days of Week')).style?.color,
        'section label',
      );

      // A selected row and an unselected row take different colours; both have
      // to survive the dark host.
      expectReadableOnLightCard(
        tester.widget<Text>(find.text('Monday')).style?.color,
        'selected day label',
      );
      expectReadableOnLightCard(
        tester.widget<Text>(find.text('Tuesday')).style?.color,
        'unselected day label',
      );
    });

    testWidgets('quick-action chip labels stay readable', (tester) async {
      await pumpDarkHosted(
        tester,
        DaysCheckboxList(selectedDays: const {}, onChanged: (_) {}),
      );

      for (final label in ['Select All', 'Weekdays', 'Weekend']) {
        expectReadableOnLightCard(
          tester.widget<Text>(find.text(label)).style?.color,
          '"$label" chip',
        );
      }
    });

    testWidgets('Weekdays selects Mon-Fri only', (tester) async {
      Set<int>? reported;

      await pumpDarkHosted(
        tester,
        DaysCheckboxList(
          selectedDays: const {},
          onChanged: (days) => reported = days,
        ),
      );

      await tester.tap(find.text('Weekdays'));
      expect(reported, {1, 2, 3, 4, 5});
    });

    testWidgets('Weekend selects Sunday and Saturday', (tester) async {
      Set<int>? reported;

      await pumpDarkHosted(
        tester,
        DaysCheckboxList(
          selectedDays: const {},
          onChanged: (days) => reported = days,
        ),
      );

      await tester.tap(find.text('Weekend'));
      expect(reported, {0, 6});
    });

    testWidgets('Select All flips to Clear All once every day is on',
        (tester) async {
      Set<int>? reported;

      await pumpDarkHosted(
        tester,
        DaysCheckboxList(
          selectedDays: const {0, 1, 2, 3, 4, 5, 6},
          onChanged: (days) => reported = days,
        ),
      );

      expect(find.text('Clear All'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);

      await tester.tap(find.text('Clear All'));
      expect(reported, isEmpty);
    });

    testWidgets('tapping a row toggles just that day', (tester) async {
      Set<int>? reported;

      await pumpDarkHosted(
        tester,
        DaysCheckboxList(
          selectedDays: const {1},
          onChanged: (days) => reported = days,
        ),
      );

      await tester.tap(find.text('Wednesday'));
      expect(reported, {1, 3});

      await tester.tap(find.text('Monday'));
      expect(reported, isEmpty);
    });
  });

  group('DropdownSkeleton', () {
    testWidgets('loading label stays readable', (tester) async {
      await pumpDarkHosted(
        tester,
        const DropdownSkeleton(label: 'Loading branches...'),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expectReadableOnLightCard(editable.style.color, 'skeleton text');
    });
  });

  group('DropdownError', () {
    testWidgets('surfaces the cause, not just the symptom', (tester) async {
      await pumpDarkHosted(
        tester,
        const DropdownError(
          message: 'Failed to load branches',
          detail: 'Not permitted (403).',
        ),
      );

      expect(find.text('Failed to load branches'), findsOneWidget);
      expect(find.text('Not permitted (403).'), findsOneWidget);

      expectReadableOnLightCard(
        tester.widget<Text>(find.text('Not permitted (403).')).style?.color,
        'error detail',
      );
    });

    testWidgets('offers no retry when none is given', (tester) async {
      await pumpDarkHosted(
        tester,
        const DropdownError(message: 'Failed to load branches'),
      );

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('retry fires when offered', (tester) async {
      var retried = 0;

      await pumpDarkHosted(
        tester,
        DropdownError(
          message: 'Failed to load branches',
          detail: 'Server error (500)',
          onRetry: () => retried++,
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });
  });
}
