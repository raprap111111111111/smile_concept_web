// test/presentation/pages/appointments/widgets/booking_calendar_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/presentation/pages/appointments/widgets/booking_calendar.dart';

void main() {
  group('DayLoad.fromCount', () {
    test('maps counts to bands at their boundaries', () {
      expect(DayLoad.fromCount(0), DayLoad.open);
      expect(DayLoad.fromCount(1), DayLoad.light);
      expect(DayLoad.fromCount(3), DayLoad.light);
      expect(DayLoad.fromCount(4), DayLoad.moderate);
      expect(DayLoad.fromCount(7), DayLoad.moderate);
      expect(DayLoad.fromCount(8), DayLoad.busy);
      expect(DayLoad.fromCount(99), DayLoad.busy);
    });

    test('an open day shows no dots, so empty reads as calm', () {
      expect(DayLoad.open.dots, 0);
      expect(DayLoad.light.dots, 1);
      expect(DayLoad.moderate.dots, 2);
      expect(DayLoad.busy.dots, 3);
    });
  });

  group('BookingCalendar', () {
    // A month starting mid-week, to catch leading-blank misalignment.
    final month = DateTime(2026, 9);
    final firstSelectable = DateTime(2026, 9, 10);

    Future<void> pump(
      WidgetTester tester, {
      DateTime? selectedDate,
      Map<String, int> dayLoad = const {},
      bool isLoading = false,
      void Function(DateTime)? onDateSelected,
      void Function(DateTime)? onMonthChanged,
      DateTime? visibleMonth,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCalendar(
              month: visibleMonth ?? month,
              selectedDate: selectedDate,
              dayLoad: dayLoad,
              isLoading: isLoading,
              firstSelectableDate: firstSelectable,
              onDateSelected: onDateSelected ?? (_) {},
              onMonthChanged: onMonthChanged ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders the month title and every day of the month',
        (tester) async {
      await pump(tester);

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      // September has 30 days, so the 31st must not be drawn.
      expect(find.text('31'), findsNothing);
    });

    testWidgets('Sept 1 2026 (a Tuesday) sits under the Tue column',
        (tester) async {
      await pump(tester);

      final tueX = tester.getCenter(find.text('Tue')).dx;
      final firstX = tester.getCenter(find.text('1')).dx;

      expect(firstX, moreOrLessEquals(tueX, epsilon: 1.0));
    });

    testWidgets('tapping a selectable day reports that date', (tester) async {
      DateTime? tapped;
      await pump(tester, onDateSelected: (d) => tapped = d);

      await tester.tap(find.text('15'));
      await tester.pump();

      expect(tapped, DateTime(2026, 9, 15));
    });

    testWidgets('a day before firstSelectableDate is not tappable',
        (tester) async {
      DateTime? tapped;
      await pump(tester, onDateSelected: (d) => tapped = d);

      // The 9th precedes firstSelectable (the 10th).
      await tester.tap(find.text('9'));
      await tester.pump();

      expect(tapped, isNull);
    });

    testWidgets('busy days are labelled for screen readers by band',
        (tester) async {
      // bySemanticsLabel needs the semantics tree built.
      final semantics = tester.ensureSemantics();

      await pump(tester, dayLoad: {
        '2026-09-10': 1, // light
        '2026-09-11': 5, // moderate
        '2026-09-12': 12, // busy
      });

      expect(find.bySemanticsLabel('Thursday, September 10, Light'),
          findsOneWidget);
      expect(find.bySemanticsLabel('Friday, September 11, Moderate'),
          findsOneWidget);
      expect(
          find.bySemanticsLabel('Saturday, September 12, Busy'), findsOneWidget);
      // A day absent from the map has no bookings.
      expect(find.bySemanticsLabel('Sunday, September 13, No bookings yet'),
          findsOneWidget);

      semantics.dispose();
    });

    testWidgets('paging back is blocked at the first selectable month',
        (tester) async {
      DateTime? changed;
      await pump(tester, onMonthChanged: (m) => changed = m);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pump();
      expect(changed, isNull, reason: 'September holds firstSelectableDate');

      await tester.tap(find.byTooltip('Next month'));
      await tester.pump();
      expect(changed, DateTime(2026, 10));
    });

    testWidgets('paging back is allowed from a later month', (tester) async {
      DateTime? changed;
      await pump(
        tester,
        visibleMonth: DateTime(2026, 10),
        onMonthChanged: (m) => changed = m,
      );

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pump();

      expect(changed, DateTime(2026, 9));
    });

    testWidgets('shows a spinner while counts are loading', (tester) async {
      await pump(tester, isLoading: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await pump(tester, isLoading: false);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
