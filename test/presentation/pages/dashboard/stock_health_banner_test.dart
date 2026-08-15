// test/presentation/pages/dashboard/stock_health_banner_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/data/models/dashboard/dashboard_stats.dart';
import 'package:smile_concept_web/presentation/pages/dashboard/components/stock_health_banner.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';

void main() {
  DashboardStats statsWith({
    int lowStock = 0,
    int expiring = 0,
    int negative = 0,
  }) {
    return DashboardStats(
      appointmentsToday: 0,
      appointmentsTodayDelta: 0,
      newPatients: 0,
      newPatientsDelta: 0,
      pendingReviews: 0,
      monthlyRevenue: 0,
      monthlyRevenueDelta: 0,
      lowStockItems: lowStock,
      expiringBatches: expiring,
      negativeStock: negative,
      appointmentsTrend: const [],
      appointmentsTodayByHour: const [],
      newPatientsTrend: const [],
      newPatientsByMonth: const [],
    );
  }

  Future<void> pump(WidgetTester tester, DashboardStats stats) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: StockHealthBanner(stats: stats),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a healthy cupboard renders nothing at all', (tester) async {
    await pump(tester, statsWith());

    // The four headline tiles answer a different question; stock only earns
    // space when something is wrong.
    expect(find.text('Stock needs attention'), findsNothing);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('low stock is reported with a count', (tester) async {
    await pump(tester, statsWith(lowStock: 3));

    expect(find.text('Stock needs attention'), findsOneWidget);
    expect(find.text('3 items need reordering'), findsOneWidget);
  });

  testWidgets('a single item reads in the singular', (tester) async {
    await pump(tester, statsWith(lowStock: 1));

    expect(find.text('1 item needs reordering'), findsOneWidget);
  });

  testWidgets('every warning kind shows at once', (tester) async {
    await pump(tester, statsWith(lowStock: 2, expiring: 4, negative: 1));

    expect(find.text('1 item is over-used'), findsOneWidget);
    expect(find.text('2 items need reordering'), findsOneWidget);
    expect(find.text('4 batches are expiring'), findsOneWidget);
  });

  testWidgets('over-used stock leads, being the most serious', (tester) async {
    await pump(tester, statsWith(lowStock: 2, expiring: 4, negative: 1));

    final overUsed = tester.getTopLeft(find.text('1 item is over-used'));
    final reorder = tester.getTopLeft(find.text('2 items need reordering'));

    expect(overUsed.dx, lessThan(reorder.dx));
  });

  testWidgets('each count carries an icon, not colour alone', (tester) async {
    await pump(tester, statsWith(negative: 1));

    // House rule: state is never encoded by colour alone.
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('only expiring batches still raises the banner', (tester) async {
    await pump(tester, statsWith(expiring: 2));

    expect(find.text('Stock needs attention'), findsOneWidget);
    expect(find.text('2 batches are expiring'), findsOneWidget);
    expect(find.textContaining('reordering'), findsNothing);
  });
}
