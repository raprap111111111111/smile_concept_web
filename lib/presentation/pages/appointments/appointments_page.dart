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

  DateTime _dateKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _parseDateKey(String value) {
    final parts = value.split('-');

    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Check if current user can view ALL appointments
  bool _canViewAll() {
    final permissionService = ref.read(permissionServiceProvider);
    return permissionService.can(AppPermissions.appointmentViewAny);
  }

  /// Get current user ID
  int? _getCurrentUserId() {
    final authState = ref.read(authStateProvider);
    return authState.user?.id;
  }

  Future<void> _loadCalendarCountsForMonth(DateTime month) async {
    if (!mounted) return;

    setState(() {
      _isLoadingCounts = true;
    });

    try {
      final state = ref.read(appointmentNotifierProvider);

      final counts =
          await ref.read(appointmentRepositoryProvider).getCalendarCounts(
                month: month,
                status: state.filter.status,
                doctorId: state.filter.doctorId,
                branchId: state.filter.branchId,
                // 🔐 SECURITY: Only include userId in filter if user cannot view all
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

      setState(() {
        _isLoadingCounts = false;
      });
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
      MaterialPageRoute(
        builder: (_) => const BookAppointmentPage(),
      ),
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

      if (mounted) {
        ToastHelper.success(context, 'Appointment deleted');
      }
    } catch (error) {
      if (mounted) {
        ToastHelper.error(context, error.toString());
      }
    }
  }

  Future<bool> _confirmDelete(AppointmentModel appointment) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Appointment'),
            content: Text(
              'Delete appointment for '
              '${appointment.user?.name ?? "this patient"}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
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
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('Cancel Appointment'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for cancellation *',
              hintText: 'e.g., Schedule conflict, sick',
              border: OutlineInputBorder(),
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
      await _updateStatus(
        appointment,
        'cancelled',
        reason: result,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentNotifierProvider);
    final notifier = ref.read(appointmentNotifierProvider.notifier);

    final permissions = ref.watch(permissionServiceProvider);

    // 🔐 PERMISSION CHECKS
    final canViewAll = permissions.can(AppPermissions.appointmentViewAny);
    final canView = permissions.can(AppPermissions.appointmentView);
    final canCreate = permissions.can(AppPermissions.appointmentCreate);
    final canDelete = permissions.can(AppPermissions.appointmentDelete);
    final canUpdateStatus =
        permissions.can(AppPermissions.appointmentUpdateStatus);
    final currentUserId = ref.watch(authStateProvider).user?.id;

    debugPrint('APPOINTMENTS PAGE - canViewAll: $canViewAll');
    debugPrint('APPOINTMENTS PAGE - canView: $canView');
    debugPrint('APPOINTMENTS PAGE - currentUserId: $currentUserId');

    // Redirect to login if no view permission
    if (!canViewAll && !canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointments')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'You do not have permission to view appointments.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(canViewAll ? 'All Appointments' : 'My Appointments'),
        centerTitle: true,
        actions: [
          if (_isLoadingCounts)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Change view',
            icon: const Icon(Icons.view_module),
            onPressed: () {
              setState(() {
                _calendarFormat = switch (_calendarFormat) {
                  CalendarFormat.month => CalendarFormat.twoWeeks,
                  CalendarFormat.twoWeeks => CalendarFormat.week,
                  CalendarFormat.week => CalendarFormat.month,
                };
              });
            },
          ),
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today),
            onPressed: () async {
              final today = DateTime.now();
              await _loadAppointmentsForDay(today);
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadCalendarCountsForMonth(_focusedDay);

              if (_selectedDay != null) {
                await _loadAppointmentsForDay(_selectedDay!);
              }
            },
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('New Appointment'),
            )
          : null,
      body: Column(
        children: [
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
          const Divider(height: 1),
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
        onRefresh: () async {
          await _loadCalendarCountsForMonth(_focusedDay);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildCalendar(),
            const Divider(height: 1),
            const SizedBox(height: 60),
            Icon(
              Icons.calendar_today_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Select a date to view appointments',
                style: TextStyle(color: Colors.grey.shade600),
              ),
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
          const Divider(height: 1),
          const SizedBox(height: 80),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 100),
        ],
      );
    }

    if (state.error != null && state.appointments.isEmpty) {
      return RefreshIndicator(
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
            const Divider(height: 1),
            const SizedBox(height: 60),
            _buildErrorContent(state.error!),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    // Filter appointments based on permission (frontend secondary check)
    List<AppointmentModel> displayedAppointments = state.appointments;

    // 🔐 If user can view all, show all. Otherwise, filter to own appointments.
    if (!canViewAll && currentUserId != null) {
      displayedAppointments = displayedAppointments
          .where((apt) => apt.userId == currentUserId)
          .toList();
    }

    final dayAppointments = [...displayedAppointments]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return RefreshIndicator(
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
          const Divider(height: 1),
          _buildSelectedDayHeader(dayAppointments.length, canViewAll),
          if (dayAppointments.isEmpty)
            _buildEmptyDay()
          else
            ...dayAppointments.map(
              (appointment) => AppointmentCalendarCard(
                appointment: appointment,
                currentUserId: currentUserId,
                canViewAll: canViewAll,
                canUpdateStatus: canUpdateStatus, // ✅ NEW
                onDelete: canDelete ? () => _delete(appointment) : null,
                // ✅ NEW: Single callback for status changes
                onStatusChanged: canUpdateStatus
                    ? (newStatus) => _updateStatus(appointment, newStatus)
                    : null,
                onCancel: canUpdateStatus
                    ? () => _showCancelDialog(appointment)
                    : null,
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: TableCalendar<AppointmentModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) {
          return _selectedDay != null && _isSameDay(_selectedDay!, day);
        },
        calendarFormat: _calendarFormat,
        eventLoader: (_) => const [],
        startingDayOfWeek: StartingDayOfWeek.monday,
        onDaySelected: (selectedDay, focusedDay) async {
          await _loadAppointmentsForDay(selectedDay);
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });

          _loadCalendarCountsForMonth(focusedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Theme.of(context).colorScheme.primary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.red.shade400),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
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
                if (markers.length < 4) {
                  markers.add(color);
                }
              }
            }

            addMarkers('pending', Colors.orange);
            addMarkers('confirmed', Colors.blue);
            addMarkers('completed', Colors.green);
            addMarkers('cancelled', Colors.red);

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
    final today = DateTime.now();
    final isToday = _isSameDay(day, today);

    final label = isToday
        ? 'Today • ${DateFormat('MMM dd').format(day)}'
        : DateFormat('EEEE, MMM dd, yyyy').format(day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isToday
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isToday
                    ? Colors.white
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count appointment${count != 1 ? "s" : ""}${canViewAll ? '' : ' (Your appointments)'}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No appointments on this day',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: const Text('Add Appointment'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String error) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              await _loadCalendarCountsForMonth(_focusedDay);

              if (_selectedDay != null) {
                await _loadAppointmentsForDay(_selectedDay!);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
