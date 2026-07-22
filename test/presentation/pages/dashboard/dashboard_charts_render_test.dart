// Renders the dashboard chart widgets with representative data at desktop and
// phone widths. Any RenderFlex overflow or layout assertion fails the test, so
// these cover the layout the palette validator cannot see.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smile_concept_web/data/models/dashboard/chart_series.dart';
import 'package:smile_concept_web/data/models/dashboard/dashboard_stats.dart';
import 'package:smile_concept_web/data/models/dashboard/recent_activity.dart';
import 'package:smile_concept_web/data/models/dashboard/today_schedule.dart';
import 'package:smile_concept_web/presentation/pages/dashboard/components/activity_card.dart';
import 'package:smile_concept_web/presentation/pages/dashboard/components/charts/appointments_trend_chart.dart';
import 'package:smile_concept_web/presentation/pages/dashboard/components/charts/chart_card.dart';
import 'package:smile_concept_web/presentation/pages/dashboard/components/charts/hourly_appointments_chart.dart';
import 'package:smile_concept_web/presentation/pages/dashboard/components/charts/new_patients_chart.dart';
import 'package:smile_concept_web/presentation/pages/dashboard/components/charts/status_breakdown_bar.dart';
import 'package:smile_concept_web/presentation/pages/dashboard/components/schedule_card.dart';
import 'package:smile_concept_web/presentation/pages/dashboard/components/stat_card.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    required double width,
  }) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('dashboard charts render', () {
    for (final width in [1440.0, 600.0]) {
      testWidgets('hourly appointments chart at ${width.toInt()}px',
          (tester) async {
        await pumpAt(
          tester,
          ChartCard(
            title: 'Appointments Today',
            subtitle: 'Bookings by start hour',
            trailing:
                const DeltaBadge(delta: -14.3, period: 'vs yesterday'),
            child: HourlyAppointmentsChart(points: _hours, highlightHour: 12),
          ),
          width: width,
        );

        expect(find.text('Appointments Today'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('new patients chart at ${width.toInt()}px', (tester) async {
        await pumpAt(
          tester,
          ChartCard(
            title: 'New Patients',
            subtitle: 'Registrations per month, last 6 months',
            child: NewPatientsChart(points: _months),
          ),
          width: width,
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('appointment volume trend at ${width.toInt()}px',
          (tester) async {
        await pumpAt(
          tester,
          ChartCard(
            title: 'Appointment Volume',
            subtitle: 'Total bookings per day, last 14 days',
            footer: TrendCaption(points: _trend),
            child: AppointmentsTrendChart(points: _trend),
          ),
          width: width,
        );

        // The caption carries the totals the chart does not direct-label.
        expect(find.text('Booked'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('schedule card at ${width.toInt()}px', (tester) async {
        await pumpAt(tester, ScheduleCard(_schedule), width: width);

        expect(find.text("Today's Schedule"), findsOneWidget);
        expect(find.text('Ramon Aquino'), findsOneWidget);
        // Every status slot is named, which is the relief channel the
        // sub-3:1 amber requires.
        expect(find.text('Confirmed'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('activity card at ${width.toInt()}px', (tester) async {
        await pumpAt(tester, ActivityCard(_activity), width: width);

        expect(find.text('Recent Activity'), findsOneWidget);
        expect(find.text('Created Appointment'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('stat tile with sparkline at ${width.toInt()}px',
          (tester) async {
        await pumpAt(
          tester,
          SizedBox(
            height: 170,
            child: StatCard(
              title: 'Appointments Today',
              value: '6',
              delta: -14.3,
              deltaPeriod: 'vs yesterday',
              accentColor: const Color(0xFF0E8FA3),
              icon: Icons.calendar_month_outlined,
              trend: _trend.map((p) => p.total).toList(),
            ),
          ),
          width: width,
        );

        expect(find.text('6'), findsOneWidget);
        expect(find.text('14%'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('status bar renders an empty day without dividing by zero',
        (tester) async {
      await pumpAt(
        tester,
        const StatusBreakdownBar(
          statuses: [
            CategoryCount(key: 'pending', label: 'Pending', count: 0),
            CategoryCount(key: 'confirmed', label: 'Confirmed', count: 0),
            CategoryCount(key: 'cancelled', label: 'Cancelled', count: 0),
            CategoryCount(key: 'completed', label: 'Completed', count: 0),
          ],
        ),
        width: 900,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('empty stats render the empty state, not a broken plot',
        (tester) async {
      await pumpAt(
        tester,
        ChartCard(
          title: 'Appointments Today',
          subtitle: 'Bookings by start hour',
          isEmpty: DashboardStats.empty.appointmentsTodayByHour.isEmpty,
          emptyMessage: 'Nothing booked today',
          child: const HourlyAppointmentsChart(points: []),
        ),
        width: 900,
      );

      expect(find.text('Nothing booked today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('model parsing', () {
    test('stats parse the API payload shape', () {
      final stats = DashboardStats.fromJson({
        'appointmentsToday': 6,
        'appointmentsTodayDelta': -14.3,
        'newPatients': 10,
        'newPatientsDelta': 100,
        'pendingReviews': 2,
        'monthlyRevenue': 0,
        'monthlyRevenueDelta': 0,
        'appointmentsTrend': [
          {
            'date': '2026-07-22',
            'label': 'Jul 22',
            'shortLabel': 'Wed',
            'total': 6,
            'completed': 0,
            'cancelled': 0,
          }
        ],
        'appointmentsTodayByHour': [
          {'hour': 10, 'label': '10 AM', 'count': 1}
        ],
        'newPatientsTrend': [
          {'date': '2026-07-22', 'label': 'Jul 22', 'shortLabel': '22', 'count': 3}
        ],
        'newPatientsByMonth': [
          {'month': '2026-07', 'label': 'Jul 2026', 'shortLabel': 'Jul', 'count': 10}
        ],
      });

      expect(stats.appointmentsToday, 6);
      expect(stats.appointmentsTodayDelta, -14.3);
      expect(stats.appointmentsTrend.single.total, 6);
      expect(stats.newPatientsByMonth.single.key, '2026-07');
      expect(stats.newPatientsTrend.single.key, '2026-07-22');
    });

    test('missing or malformed series degrade to empty lists', () {
      final stats = DashboardStats.fromJson({'appointmentsToday': '4'});

      expect(stats.appointmentsToday, 4);
      expect(stats.appointmentsTrend, isEmpty);
      expect(stats.newPatientsByMonth, isEmpty);
    });

    test('schedule keys status counts off the `status` field', () {
      final schedule = TodaySchedule.fromJson({
        'date': '2026-07-22',
        'total': 1,
        'appointments': [
          {
            'id': 1,
            'time': '10:15 AM',
            'patientName': 'Ramon Aquino',
            'type': 'Consultation',
            'status': 'pending',
            'doctorName': 'Dr. Cruz',
            'durationMinutes': 45,
          }
        ],
        'byStatus': [
          {'status': 'pending', 'label': 'Pending', 'count': 1}
        ],
      });

      expect(schedule.appointments.single.patientName, 'Ramon Aquino');
      expect(schedule.byStatus.single.key, 'pending');
    });
  });
}

final _hours = [
  for (var hour = 7; hour <= 20; hour++)
    HourlyPoint(
      hour: hour,
      label: '$hour:00',
      count: [0, 0, 0, 1, 0, 2, 1, 0, 1, 1, 0, 0, 0, 0][hour - 7],
    ),
];

final _months = [
  for (final entry in const [
    ['2026-02', 'Feb', 4],
    ['2026-03', 'Mar', 7],
    ['2026-04', 'Apr', 5],
    ['2026-05', 'May', 9],
    ['2026-06', 'Jun', 6],
    ['2026-07', 'Jul', 10],
  ])
    CountPoint(
      key: entry[0] as String,
      label: '${entry[1]} 2026',
      shortLabel: entry[1] as String,
      count: entry[2] as int,
    ),
];

final _trend = [
  for (var i = 0; i < 14; i++)
    AppointmentTrendPoint(
      date: '2026-07-${(9 + i).toString().padLeft(2, '0')}',
      label: 'Jul ${9 + i}',
      shortLabel: 'D$i',
      total: const [4, 7, 2, 1, 7, 7, 6, 9, 7, 3, 0, 8, 7, 6][i],
      completed: const [3, 6, 2, 1, 5, 6, 5, 8, 6, 2, 0, 7, 6, 0][i],
      cancelled: const [1, 1, 0, 0, 2, 1, 1, 1, 1, 1, 0, 1, 1, 0][i],
    ),
];

const _schedule = TodaySchedule(
  date: '2026-07-22',
  total: 6,
  appointments: [
    ScheduleEntry(
      id: 1,
      time: '10:15 AM',
      startTime: null,
      endTime: null,
      durationMinutes: 45,
      patientName: 'Ramon Aquino',
      type: 'Consultation',
      status: 'pending',
      doctorName: 'Dr. Juvile Ann Legislador Mansader',
    ),
    ScheduleEntry(
      id: 2,
      time: '12:15 PM',
      startTime: null,
      endTime: null,
      durationMinutes: 60,
      patientName: 'Paulo Cruz',
      type: 'Braces Adjustment',
      status: 'confirmed',
      doctorName: 'Dr. Juvile Ann Legislador Mansader',
    ),
  ],
  byHour: [],
  byStatus: [
    CategoryCount(key: 'completed', label: 'Completed', count: 0),
    CategoryCount(key: 'confirmed', label: 'Confirmed', count: 4),
    CategoryCount(key: 'pending', label: 'Pending', count: 2),
    CategoryCount(key: 'cancelled', label: 'Cancelled', count: 0),
  ],
);

const _activity = RecentActivityFeed(
  activities: [
    ActivityEntry(
      id: 1,
      action: 'created',
      subjectType: 'Appointment',
      patientName: 'Admin User',
      description: 'Created Appointment',
      timeAgo: '5 minutes ago',
      createdAt: null,
    ),
    ActivityEntry(
      id: 2,
      action: 'updated',
      subjectType: 'PatientProfile',
      patientName: 'Reception Desk',
      description: 'Updated Patient Profile',
      timeAgo: '1 hour ago',
      createdAt: null,
    ),
  ],
  byType: [
    CategoryCount(key: 'Appointment', label: 'Appointment', count: 12),
    CategoryCount(key: 'User', label: 'User', count: 11),
  ],
  byDay: [
    CountPoint(key: '2026-07-20', label: 'Jul 20', shortLabel: 'Mon', count: 4),
    CountPoint(key: '2026-07-21', label: 'Jul 21', shortLabel: 'Tue', count: 9),
    CountPoint(key: '2026-07-22', label: 'Jul 22', shortLabel: 'Wed', count: 6),
  ],
);
