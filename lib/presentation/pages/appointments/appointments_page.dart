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
import '../../theme/app_theme.dart';
import 'appointment_form_page.dart';
import 'book_appointment_page.dart';
import 'widgets/appointment_agenda_tile.dart';
import 'widgets/appointment_calendar_card.dart';
import 'widgets/appointment_detail_page.dart';
import 'widgets/appointment_filter_bar.dart';
import '../../widgets/shared/hold_to_delete_dialog.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

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

  // Patients land on a plain Upcoming/Past agenda list by default — no
  // calendar-date tap required. Staff always start on the calendar; this
  // stays false and untouched for them.
  bool _showAgenda = false;

  bool get _isPatientRole =>
      ref.read(permissionServiceProvider).role == 'patient';

  @override
  void initState() {
    super.initState();
    _selectedDay = null;
    _showAgenda = _isPatientRole;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarCountsForMonth(_focusedDay);
      if (_showAgenda) {
        ref.read(appointmentNotifierProvider.notifier).load(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _dateKey(DateTime date) => DateTime(date.year, date.month, date.day);

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

  Future<void> _handleViewToggle(bool agenda) async {
    setState(() => _showAgenda = agenda);
    // `state.appointments` is shared between calendar-day mode (loadForDate)
    // and agenda mode (load) — reload the right shape on every flip or the
    // two modes show stale/mislabeled data.
    if (agenda) {
      await ref.read(appointmentNotifierProvider.notifier).load(reset: true);
    } else if (_selectedDay != null) {
      await _loadAppointmentsForDay(_selectedDay!);
    }
  }

  Future<void> _openDetail(
    AppointmentModel appointment, {
    required bool canEdit,
    required bool canCancel,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailPage(
          appointment: appointment,
          canEdit: canEdit,
          canCancel: canCancel,
          onCancel: canCancel ? () => _showCancelDialog(appointment) : null,
        ),
      ),
    );

    // The detail page is a point-in-time snapshot with no live provider
    // binding, so an edit or cancel made inside it won't reflect back here
    // on its own — refresh once it's popped.
    if (mounted) {
      await ref.read(appointmentNotifierProvider.notifier).load(reset: true);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<AppointmentModel>(
      MaterialPageRoute(builder: (_) => const BookAppointmentPage()),
    );

    if (created == null || !mounted) return;

    await _loadCalendarCountsForMonth(created.startTime);
    if (!mounted) return;

    if (_showAgenda) {
      // Drop the patient straight into the detail page: unambiguous
      // confirmation of what was just booked, no hunting through a list.
      final permissions = ref.read(permissionServiceProvider);
      await _openDetail(
        created,
        canEdit: permissions.can(Perm.appointmentUpdate) ||
            permissions.can(Perm.appointmentReschedule),
        canCancel: permissions.can(Perm.appointmentUpdateStatus) ||
            permissions.can(Perm.appointmentCancel),
      );
    } else {
      setState(() {
        _selectedDay = created.startTime;
        _focusedDay = created.startTime;
      });

      await ref
          .read(appointmentNotifierProvider.notifier)
          .loadForDate(created.startTime);
    }

    if (mounted) {
      ToastHelper.success(context, 'Appointment created successfully');
    }
  }

  Future<void> _openEdit(AppointmentModel appointment) async {
    final updated = await Navigator.of(context).push<AppointmentModel>(
      MaterialPageRoute(
        builder: (_) => AppointmentFormPage(existingAppointment: appointment),
      ),
    );

    if (updated == null || !mounted) return;

    await _loadCalendarCountsForMonth(updated.startTime);
    setState(() {
      _selectedDay = updated.startTime;
      _focusedDay = updated.startTime;
    });

    await ref
        .read(appointmentNotifierProvider.notifier)
        .loadForDate(updated.startTime);

    if (mounted) {
      ToastHelper.success(context, 'Appointment updated successfully');
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
      if (mounted) ToastHelper.error(context, describeError(error));
    }
  }

  Future<bool> _confirmDelete(AppointmentModel appointment) async {
    return await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete Appointment',
      itemName: appointment.user?.name ?? 'this patient',
      description: 'You are about to delete the appointment for '
          '${appointment.user?.name ?? "this patient"}. '
          'This action cannot be undone.',
    );
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
      // Dialogs build off the root navigator, so they miss any Theme a page
      // wraps itself in — pin the light theme here too, or the reason field
      // draws near-white text on the white dialog.
      builder: (context) => Theme(
        data: AppTheme.lightTheme,
        child: AlertDialog(
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
              Text('Cancel Appointment', style: AppTextStyles.titleMedium),
            ],
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: reasonController,
              style: AppTextStyles.inputText,
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
    // Either permission opens the form: `create` books for yourself,
    // `create-for-others` books on a patient's behalf. A role holding only the
    // latter still needs the button.
    final canCreate = permissions.can(Perm.appointmentCreate) ||
        permissions.can(Perm.appointmentCreateForOthers);
    final canDelete = permissions.can(Perm.appointmentDelete);
    final canUpdateStatus = permissions.can(Perm.appointmentUpdateStatus);
    final canUpdate = permissions.can(Perm.appointmentUpdate);
    final canReschedule = permissions.can(Perm.appointmentReschedule);
    final canCancelPerm = permissions.can(Perm.appointmentCancel);
    final currentUserId = ref.watch(authStateProvider).user?.id;
    final isPatient = permissions.role == 'patient';

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
            _buildHeader(canViewAll, isPatient: isPatient),
            const SizedBox(height: AppDimensions.paddingMedium),
            AppointmentFilterBar(
              selectedStatus: state.filter.status,
              onStatusChanged: (status) async {
                final newFilter = status == null
                    ? state.filter.copyWith(clearStatus: true)
                    : state.filter.copyWith(status: status);

                notifier.setFilter(newFilter);
                if (isPatient && _showAgenda) {
                  await ref
                      .read(appointmentNotifierProvider.notifier)
                      .load(reset: true);
                } else {
                  await _loadCalendarCountsForMonth(_focusedDay);
                  if (_selectedDay != null) {
                    await _loadAppointmentsForDay(_selectedDay!);
                  }
                }
              },
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Expanded(
              child: (isPatient && _showAgenda)
                  ? _buildAgendaBody(
                      state,
                      canViewAll: canViewAll,
                      currentUserId: currentUserId,
                      canUpdate: canUpdate,
                      canUpdateStatus: canUpdateStatus,
                      canReschedule: canReschedule,
                      canCancelPerm: canCancelPerm,
                    )
                  : _buildBody(
                      state,
                      canViewAll: canViewAll,
                      currentUserId: currentUserId,
                      canDelete: canDelete,
                      canUpdateStatus: canUpdateStatus,
                      canUpdate: canUpdate,
                      canReschedule: canReschedule,
                      canCancelPerm: canCancelPerm,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────
  Widget _buildHeader(bool canViewAll, {required bool isPatient}) {
    // Calendar-format cycling and "jump to today" only mean anything while
    // the calendar is on screen — hide them in the patient agenda view.
    final showCalendarControls = !(isPatient && _showAgenda);
    return LayoutBuilder(
      builder: (context, constraints) {
        // The labelled toggle needs room the header does not always have;
        // below this it falls back to icons (tooltips carry the meaning).
        final compact = constraints.maxWidth < 620;

        return _buildHeaderCard(
          canViewAll,
          isPatient: isPatient,
          showCalendarControls: showCalendarControls,
          compact: compact,
        );
      },
    );
  }

  Widget _buildHeaderCard(
    bool canViewAll, {
    required bool isPatient,
    required bool showCalendarControls,
    required bool compact,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
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
          // ── Left side (icon + title) ─── wrapped in Expanded ──
          Expanded(
            child: Row(
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
                // ✅ Wrap Column in Expanded so text can shrink/wrap
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        canViewAll ? 'All Appointments' : 'My Appointments',
                        style: AppTextStyles.headlineSmall,
                        overflow: TextOverflow.ellipsis, // ✅ prevent overflow
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPatient
                            ? 'Your upcoming and past visits'
                            : 'Manage patient bookings by date',
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis, // ✅ prevent overflow
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Right side (action buttons) ────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPatient) ...[
                _ViewToggle(
                  showAgenda: _showAgenda,
                  onChanged: _handleViewToggle,
                  compact: compact,
                ),
                const SizedBox(width: 6),
              ],
              if (_isLoadingCounts && showCalendarControls)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (showCalendarControls) ...[
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
                const SizedBox(width: 6),
                _IconTile(
                  tooltip: 'Today',
                  icon: Icons.today_outlined,
                  onTap: () async {
                    await _loadAppointmentsForDay(DateTime.now());
                  },
                ),
                const SizedBox(width: 6),
              ],
              _IconTile(
                tooltip: 'Refresh',
                icon: Icons.refresh_rounded,
                onTap: () async {
                  if (isPatient && _showAgenda) {
                    await ref
                        .read(appointmentNotifierProvider.notifier)
                        .load(reset: true);
                  } else {
                    await _loadCalendarCountsForMonth(_focusedDay);
                    if (_selectedDay != null) {
                      await _loadAppointmentsForDay(_selectedDay!);
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── AGENDA (patients) ──────────────────────────────────────
  Widget _buildAgendaBody(
    AppointmentListState state, {
    required bool canViewAll,
    required int? currentUserId,
    required bool canUpdate,
    required bool canUpdateStatus,
    required bool canReschedule,
    required bool canCancelPerm,
  }) {
    Future<void> refresh() =>
        ref.read(appointmentNotifierProvider.notifier).load(reset: true);

    if (state.isLoading && state.appointments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.appointments.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _ErrorCard(error: state.error!, onRetry: refresh),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    var appointments = state.appointments;
    if (!canViewAll && currentUserId != null) {
      appointments =
          appointments.where((apt) => apt.userId == currentUserId).toList();
    }

    // Bucket by time, not status, so an in-progress visit still reads as
    // upcoming and a cancelled-but-future one stays visible with its badge.
    final upcoming = appointments.where((apt) => !apt.isPast).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final past = appointments.where((apt) => apt.isPast).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    Widget tileFor(AppointmentModel appointment) {
      final isOwn = appointment.userId == currentUserId;
      final isActive = appointment.status == AppointmentStatus.pending ||
          appointment.status == AppointmentStatus.confirmed;

      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
        child: AppointmentAgendaTile(
          appointment: appointment,
          onTap: () => _openDetail(
            appointment,
            canEdit: canUpdate || (canReschedule && isOwn && isActive),
            canCancel: canUpdateStatus || (canCancelPerm && isOwn && isActive),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (upcoming.isEmpty && past.isEmpty)
            _EmptyStateCard(
              icon: Icons.event_available_outlined,
              title: 'No appointments yet',
              subtitle: 'Tap "New Appointment" below to book your first visit',
            )
          else ...[
            _AgendaSectionHeader(title: 'Upcoming', count: upcoming.length),
            if (upcoming.isEmpty)
              _EmptyStateCard(
                icon: Icons.event_available_outlined,
                title: 'No upcoming appointments',
                subtitle: 'Tap "New Appointment" below to book your next visit',
              )
            else
              ...upcoming.map(tileFor),
            if (past.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              _AgendaSectionHeader(title: 'Past', count: past.length),
              ...past.map(tileFor),
              if (state.hasNextPage)
                Padding(
                  padding:
                      const EdgeInsets.only(top: AppDimensions.paddingSmall),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: state.isLoadingMore
                          ? null
                          : () => ref
                              .read(appointmentNotifierProvider.notifier)
                              .loadMore(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                      ),
                      icon: state.isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.expand_more_rounded, size: 20),
                      label: const Text('Show older appointments'),
                    ),
                  ),
                ),
            ],
          ],
          const SizedBox(height: 100),
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
    required bool canUpdate,
    required bool canReschedule,
    required bool canCancelPerm,
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
              (appointment) {
                // Staff (update) → any appointment.
                // Patient (reschedule) → own pending/confirmed only.
                final isOwn = appointment.userId == currentUserId;
                final isActive =
                    appointment.status == AppointmentStatus.pending ||
                        appointment.status == AppointmentStatus.confirmed;
                final canEditThis =
                    canUpdate || (canReschedule && isOwn && isActive);
                final canCancelThis =
                    canUpdateStatus || (canCancelPerm && isOwn && isActive);

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingSmall,
                  ),
                  child: AppointmentCalendarCard(
                    appointment: appointment,
                    currentUserId: currentUserId,
                    canViewAll: canViewAll,
                    canUpdateStatus: canUpdateStatus,
                    canCancel: canCancelThis,
                    onEdit: canEditThis ? () => _openEdit(appointment) : null,
                    onDelete: canDelete ? () => _delete(appointment) : null,
                    onStatusChanged: canUpdateStatus
                        ? (newStatus) => _updateStatus(appointment, newStatus)
                        : null,
                    onCancel: canCancelThis
                        ? () => _showCancelDialog(appointment)
                        : null,
                  ),
                );
              },
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
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
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
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
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
                color:
                    isToday ? AppColors.textOnPrimary : AppColors.primaryDark,
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
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
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
          Text('No appointments on this day', style: AppTextStyles.titleSmall),
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

/// List/calendar switch shown to patients only.
class _ViewToggle extends StatelessWidget {
  final bool showAgenda;
  final ValueChanged<bool> onChanged;
  final bool compact;

  const _ViewToggle({
    required this.showAgenda,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleSegment(
            tooltip: 'List view',
            icon: Icons.view_agenda_outlined,
            label: compact ? null : 'List',
            isActive: showAgenda,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 3),
          _ViewToggleSegment(
            tooltip: 'Calendar view',
            icon: Icons.calendar_month_outlined,
            label: compact ? null : 'Calendar',
            isActive: !showAgenda,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleSegment extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final String? label;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleSegment({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
    );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? AppColors.primary : Colors.transparent,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: label == null ? 9 : 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isActive
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                ),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaSectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _AgendaSectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.titleSmall),
          const SizedBox(width: AppDimensions.paddingXS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.4,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
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
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
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