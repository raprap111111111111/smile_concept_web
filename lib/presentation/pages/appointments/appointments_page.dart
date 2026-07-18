// lib/presentation/pages/appointments/appointments_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../data/models/appointment/appointment_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../providers/appointment/appointment_provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/permission_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'book_appointment_page.dart';
import 'widgets/appointment_calendar_card.dart';
import 'widgets/appointment_filter_bar.dart';

class AppointmentsPage extends ConsumerStatefulWidget {
  const AppointmentsPage({super.key});

  @override
  ConsumerState<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends ConsumerState<AppointmentsPage> {
  final _searchController = TextEditingController();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, Map<String, int>> _calendarCounts = {};

  bool _isLoadingCounts = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarCountsForMonth(_focusedDay);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _dateKey(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _parseDateKey(String value) {
    final parts = value.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  bool _canViewAll() {
    final permissionService = ref.read(permissionServiceProvider);
    return permissionService.can(Perm.appointmentViewAny);
  }

  int? _getCurrentUserId() {
    final authState = ref.read(authStateProvider);
    return authState.user?.id;
  }

  Future<void> _loadCalendarCountsForMonth(DateTime month) async {
    if (!mounted) return;
    setState(() => _isLoadingCounts = true);

    try {
      final state = ref.read(appointmentNotifierProvider);
      final counts =
          await ref.read(appointmentRepositoryProvider).getCalendarCounts(
                month: month,
                status: state.filter.status,
                doctorId: state.filter.doctorId,
                branchId: state.filter.branchId,
                userId: _canViewAll() ? null : _getCurrentUserId(),
              );

      if (!mounted) return;
      setState(() {
        _calendarCounts.clear();
        counts.forEach((dateString, value) {
          _calendarCounts[_parseDateKey(dateString)] = value;
        });
        _isLoadingCounts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCounts = false);
    }
  }

  Future<void> _loadAppointmentsForDay(DateTime day) async {
    final notifier = ref.read(appointmentNotifierProvider.notifier);
    setState(() {
      _selectedDay = day;
      _focusedDay = day;
    });
    await notifier.loadForDate(day);
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<AppointmentModel>(
      MaterialPageRoute(builder: (_) => const BookAppointmentPage()),
    );

    if (created == null || !mounted) return;

    await _loadCalendarCountsForMonth(created.startTime);
    setState(() {
      _selectedDay = created.startTime;
      _focusedDay = created.startTime;
    });

    await ref
        .read(appointmentNotifierProvider.notifier)
        .loadForDate(created.startTime);

    if (mounted) {
      ToastHelper.success(context, 'Appointment created successfully');
    }
  }

  Future<void> _delete(AppointmentModel appointment) async {
    final ok = await _confirmDelete(appointment);
    if (!ok) return;

    try {
      await ref
          .read(appointmentRepositoryProvider)
          .deleteAppointment(appointment.id);

      ref
          .read(appointmentNotifierProvider.notifier)
          .removeAppointment(appointment.id);

      await _loadCalendarCountsForMonth(_focusedDay);
      if (_selectedDay != null) {
        await _loadAppointmentsForDay(_selectedDay!);
      }

      if (mounted) ToastHelper.success(context, 'Appointment deleted');
    } catch (error) {
      if (mounted) ToastHelper.error(context, error.toString());
    }
  }

  Future<bool> _confirmDelete(AppointmentModel appointment) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
            ),
            title: Text(
              'Delete Appointment',
              style: AppTextStyles.titleMedium,
            ),
            content: Text(
              'Delete appointment for ${appointment.user?.name ?? "this patient"}?',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _updateStatus(
    AppointmentModel appointment,
    String status, {
    String? reason,
  }) async {
    final success =
        await ref.read(appointmentNotifierProvider.notifier).updateStatus(
              id: appointment.id,
              status: status,
              cancellationReason: reason,
            );

    if (!mounted) return;

    if (success) {
      await _loadCalendarCountsForMonth(_focusedDay);
      if (_selectedDay != null) {
        await _loadAppointmentsForDay(_selectedDay!);
      }
      if (mounted) {
        ToastHelper.success(
          context,
          'Status updated to ${status.toUpperCase()}',
        );
      }
    } else {
      final error =
          ref.read(appointmentNotifierProvider).error ?? 'Unknown error';
      ToastHelper.error(context, error);
    }
  }

  Future<void> _showCancelDialog(AppointmentModel appointment) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text('Cancel Appointment',
                style: AppTextStyles.titleMedium),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for cancellation *',
              hintText: 'e.g., Schedule conflict, sick',
            ),
            maxLines: 3,
            maxLength: 500,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Reason is required';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    reasonController.dispose();

    if (result != null && result.isNotEmpty) {
      await _updateStatus(appointment, 'cancelled', reason: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentNotifierProvider);
    final notifier = ref.read(appointmentNotifierProvider.notifier);

    final permissions = ref.watch(permissionServiceProvider);
    final canViewAll = permissions.can(Perm.appointmentViewAny);
    final canView = permissions.can(Perm.appointmentView);
    final canCreate = permissions.can(Perm.appointmentCreate);
    final canDelete = permissions.can(Perm.appointmentDelete);
    final canUpdateStatus = permissions.can(Perm.appointmentUpdateStatus);
    final currentUserId = ref.watch(authStateProvider).user?.id;

    if (!canViewAll && !canView) {
      return _NoAccessView();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Appointment',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(canViewAll),
            const SizedBox(height: AppDimensions.paddingMedium),
            AppointmentFilterBar(
              selectedStatus: state.filter.status,
              onStatusChanged: (status) async {
                final newFilter = status == null
                    ? state.filter.copyWith(clearStatus: true)
                    : state.filter.copyWith(status: status);

                notifier.setFilter(newFilter);
                await _loadCalendarCountsForMonth(_focusedDay);
                if (_selectedDay != null) {
                  await _loadAppointmentsForDay(_selectedDay!);
                }
              },
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Expanded(
              child: _buildBody(
                state,
                canViewAll: canViewAll,
                currentUserId: currentUserId,
                canDelete: canDelete,
                canUpdateStatus: canUpdateStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────
  Widget _buildHeader(bool canViewAll) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.textOnPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    canViewAll ? 'All Appointments' : 'My Appointments',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage patient bookings by date',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (_isLoadingCounts)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              _IconTile(
                tooltip: 'Change view',
                icon: Icons.view_module_outlined,
                onTap: () {
                  setState(() {
                    _calendarFormat = switch (_calendarFormat) {
                      CalendarFormat.month => CalendarFormat.twoWeeks,
                      CalendarFormat.twoWeeks => CalendarFormat.week,
                      CalendarFormat.week => CalendarFormat.month,
                    };
                  });
                },
              ),
              const SizedBox(width: 8),
              _IconTile(
                tooltip: 'Today',
                icon: Icons.today_outlined,
                onTap: () async {
                  await _loadAppointmentsForDay(DateTime.now());
                },
              ),
              const SizedBox(width: 8),
              _IconTile(
                tooltip: 'Refresh',
                icon: Icons.refresh_rounded,
                onTap: () async {
                  await _loadCalendarCountsForMonth(_focusedDay);
                  if (_selectedDay != null) {
                    await _loadAppointmentsForDay(_selectedDay!);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AppointmentListState state, {
    required bool canViewAll,
    required int? currentUserId,
    required bool canDelete,
    required bool canUpdateStatus,
  }) {
    if (_selectedDay == null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadCalendarCountsForMonth(_focusedDay),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildCalendar(),
            const SizedBox(height: AppDimensions.paddingLarge),
            _EmptyStateCard(
              icon: Icons.calendar_today_outlined,
              title: 'Select a date to view appointments',
              subtitle: 'Pick any date on the calendar above',
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    if (state.isLoading && state.appointments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildCalendar(),
          const SizedBox(height: 80),
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          const SizedBox(height: 100),
        ],
      );
    }

    if (state.error != null && state.appointments.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await _loadCalendarCountsForMonth(_focusedDay);
          if (_selectedDay != null) {
            await _loadAppointmentsForDay(_selectedDay!);
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildCalendar(),
            const SizedBox(height: AppDimensions.paddingLarge),
            _ErrorCard(
              error: state.error!,
              onRetry: () async {
                await _loadCalendarCountsForMonth(_focusedDay);
                if (_selectedDay != null) {
                  await _loadAppointmentsForDay(_selectedDay!);
                }
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    List<AppointmentModel> displayedAppointments = state.appointments;

    if (!canViewAll && currentUserId != null) {
      displayedAppointments = displayedAppointments
          .where((apt) => apt.userId == currentUserId)
          .toList();
    }

    final dayAppointments = [...displayedAppointments]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await _loadCalendarCountsForMonth(_focusedDay);
        if (_selectedDay != null) {
          await _loadAppointmentsForDay(_selectedDay!);
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildCalendar(),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildSelectedDayHeader(dayAppointments.length, canViewAll),
          if (dayAppointments.isEmpty)
            _buildEmptyDay()
          else
            ...dayAppointments.map(
              (appointment) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppDimensions.paddingSmall,
                ),
                child: AppointmentCalendarCard(
                  appointment: appointment,
                  currentUserId: currentUserId,
                  canViewAll: canViewAll,
                  canUpdateStatus: canUpdateStatus,
                  onDelete: canDelete ? () => _delete(appointment) : null,
                  onStatusChanged: canUpdateStatus
                      ? (newStatus) => _updateStatus(appointment, newStatus)
                      : null,
                  onCancel: canUpdateStatus
                      ? () => _showCancelDialog(appointment)
                      : null,
                ),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── CALENDAR ───────────────────────────────────────────────
  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      child: TableCalendar<AppointmentModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) =>
            _selectedDay != null && _isSameDay(_selectedDay!, day),
        calendarFormat: _calendarFormat,
        eventLoader: (_) => const [],
        startingDayOfWeek: StartingDayOfWeek.monday,
        onDaySelected: (selectedDay, focusedDay) async {
          await _loadAppointmentsForDay(selectedDay);
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
          _loadCalendarCountsForMonth(focusedDay);
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppTextStyles.titleMedium,
          leftChevronIcon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.primary,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          weekendStyle: AppTextStyles.labelMedium.copyWith(
            color: AppColors.error,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.ink,
          ),
          weekendTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.error,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          todayTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w800,
          ),
          markersMaxCount: 4,
          markerSize: 5,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            final counts = _calendarCounts[_dateKey(day)];
            if (counts == null || (counts['total'] ?? 0) <= 0) {
              return const SizedBox();
            }

            final markers = <Color>[];
            void addMarkers(String status, Color color) {
              final count = counts[status] ?? 0;
              for (var i = 0; i < count; i++) {
                if (markers.length < 4) markers.add(color);
              }
            }

            addMarkers('pending', AppColors.statusPending);
            addMarkers('confirmed', AppColors.statusBooked);
            addMarkers('completed', AppColors.statusCompleted);
            addMarkers('cancelled', AppColors.statusCancelled);

            if (markers.isEmpty) return const SizedBox();

            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: markers.map((color) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayHeader(int count, bool canViewAll) {
    final day = _selectedDay ?? DateTime.now();
    final isToday = _isSameDay(day, DateTime.now());
    final label = isToday
        ? 'Today • ${DateFormat('MMM dd').format(day)}'
        : DateFormat('EEEE, MMM dd, yyyy').format(day);

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : AppColors.accentLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isToday
                    ? AppColors.textOnPrimary
                    : AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Text(
              '$count appointment${count != 1 ? "s" : ""}'
              '${canViewAll ? '' : ' (Your appointments)'}',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.paddingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text('No appointments on this day',
              style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Text(
            'Book a new appointment for this date',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          FilledButton.icon(
            onPressed: _openCreate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Appointment'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ────────────────────────────────────────

class _IconTile extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _IconTile({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _NoAccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Text('Access Denied', style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              Text(
                'You do not have permission to view appointments.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}