// lib/presentation/pages/appointments/appointment_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../data/models/appointment/appointment_model.dart';
import '../../../data/models/appointment/appointment_request.dart';
import '../../../data/models/patient/patient_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/doctor_repository.dart';
import '../../providers/appointment/appointment_provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/branch/branch_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/patient_search_field.dart';
import 'widgets/time_slot_picker.dart';

class AppointmentFormPage extends ConsumerStatefulWidget {
  final AppointmentModel? existingAppointment;

  const AppointmentFormPage({
    super.key,
    this.existingAppointment,
  });

  @override
  ConsumerState<AppointmentFormPage> createState() =>
      _AppointmentFormPageState();
}

class _AppointmentFormPageState extends ConsumerState<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  int? _doctorId;
  int? _branchId;
  int? _userId;
  String? _selectedPatientName;
  DateTime? _selectedDate;
  String _status = 'pending';
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingAppointment != null;

  @override
  void initState() {
    super.initState();

    final appointment = widget.existingAppointment;

    if (appointment != null) {
      _doctorId = appointment.doctorId;
      _branchId = appointment.branchId;
      _userId = appointment.userId;
      _selectedDate = appointment.startTime;
      _status = appointment.status.name;
      _selectedPatientName = appointment.user?.name;
      _reasonController.text = appointment.reasonForVisit ?? '';
    }

    // Clear any slot selection left over from a previous booking session,
    // otherwise _submit could silently reuse a stale slot time.
    Future.microtask(() {
      if (mounted) {
        ref.read(availabilityNotifierProvider.notifier).clearSlots();
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    if (_doctorId == null || _branchId == null || _selectedDate == null) {
      return;
    }
    await ref.read(availabilityNotifierProvider.notifier).fetchSlots(
          doctorId: _doctorId!,
          branchId: _branchId!,
          date: _selectedDate!,
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.background,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() => _selectedDate = picked);
    ref.read(availabilityNotifierProvider.notifier).clearSlots();
    await _fetchSlots();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final permissionService = ref.read(permissionServiceProvider);
    final currentUser = ref.read(authStateProvider).user;

    final canCreateSelf = permissionService.can(Perm.appointmentCreate);
    final canCreateForOthers =
        permissionService.can(Perm.appointmentCreateForOthers);
    final canUpdateStatus = permissionService.can(Perm.appointmentUpdateStatus);
    final canUpdate = permissionService.can(Perm.appointmentUpdate);
    final canReschedule = permissionService.can(Perm.appointmentReschedule);

    if (_isEditing) {
      if (!canUpdate && !canReschedule) {
        _showError('You do not have permission to update appointments.');
        return;
      }
    } else if (!canCreateSelf && !canCreateForOthers) {
      _showError('You do not have permission to create appointments.');
      return;
    }

    final slotState = ref.read(availabilityNotifierProvider);
    final selectedSlot = slotState.selectedSlot;

    if (selectedSlot == null && !_isEditing) {
      _showError('Please select a time slot.');
      return;
    }

    if (!_isEditing && canCreateForOthers && _userId == null) {
      _showError('Please select a patient.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(appointmentRepositoryProvider);
      AppointmentModel result;

      final reasonForVisit = _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim();

      if (_isEditing) {
        final existing = widget.existingAppointment!;
        final targetUserId = canCreateForOthers
            ? (_userId ?? existing.userId)
            : existing.userId;

        final request = AppointmentRequest(
          doctorId: _doctorId ?? existing.doctorId,
          branchId: _branchId ?? existing.branchId,
          startTime: selectedSlot != null
              ? selectedSlot.startDateTime
              : existing.startTime,
          endTime: selectedSlot != null
              ? selectedSlot.endDateTime
              : existing.endTime,
          userId: targetUserId,
          status: canUpdateStatus ? _status : existing.status.name,
          reasonForVisit: reasonForVisit,
        );

        result = await repo.updateAppointment(
          id: existing.id,
          request: request,
        );
      } else {
        final targetUserId = canCreateForOthers ? _userId : currentUser?.id;

        final request = AppointmentRequest(
          doctorId: _doctorId!,
          branchId: _branchId!,
          startTime: selectedSlot!.startDateTime,
          endTime: selectedSlot.endDateTime,
          userId: targetUserId,
          status: _status,
          reasonForVisit: reasonForVisit,
        );

        result = await repo.createAppointment(request);
      }

      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError(error.toString());
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availState = ref.watch(availabilityNotifierProvider);
    final doctorsAsync = ref.watch(doctorsProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final permissionService = ref.watch(permissionServiceProvider);
    final currentUser = ref.watch(authStateProvider).user;

    final canCreateForOthers =
        permissionService.can(Perm.appointmentCreateForOthers);
    final canUpdateStatus =
        permissionService.can(Perm.appointmentUpdateStatus);

    // Reschedule-only users (patients) can change date/time + reason,
    // but not the doctor or branch — the API strips those fields anyway.
    final lockClinicians =
        _isEditing && !permissionService.can(Perm.appointmentUpdate);

    final dateLabel = _selectedDate != null
        ? DateFormat('EEE, MMM dd yyyy').format(_selectedDate!)
        : 'Select Date';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildFormCard(
                  doctorsAsync: doctorsAsync,
                  branchesAsync: branchesAsync,
                  availState: availState,
                  canCreateForOthers: canCreateForOthers,
                  canUpdateStatus: canUpdateStatus,
                  lockClinicians: lockClinicians,
                  currentUser: currentUser,
                  dateLabel: dateLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────
  Widget _buildHeader() {
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
            child: Icon(
              _isEditing ? Icons.edit_calendar_rounded : Icons.event_available_rounded,
              color: AppColors.textOnPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Appointment' : 'New Appointment',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  _isEditing
                      ? 'Update patient booking details'
                      : 'Book a new patient appointment',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── FORM CARD ──────────────────────────────────────────────
  Widget _buildFormCard({
    required AsyncValue doctorsAsync,
    required AsyncValue branchesAsync,
    required dynamic availState,
    required bool canCreateForOthers,
    required bool canUpdateStatus,
    required bool lockClinicians,
    required dynamic currentUser,
    required String dateLabel,
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Appointment Details'),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Doctor ─────────────────────────────────────
            _fieldLabel('Doctor', required: true),
            doctorsAsync.when(
              loading: () => const LinearProgressIndicator(color: AppColors.primary),
              error: (error, _) => Text(
                'Failed to load doctors: $error',
                style: const TextStyle(color: AppColors.error),
              ),
              data: (doctors) => DropdownButtonFormField<int>(
                initialValue: _doctorId,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Select Doctor',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                items: (doctors as List).map((doctor) {
                  final id = doctor['id'] as int;
                  final name = doctor['name']?.toString() ??
                      (doctor['user'] as Map?)?['name']?.toString() ??
                      'Doctor #$id';
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: lockClinicians
                    ? null
                    : (value) {
                        setState(() => _doctorId = value);
                        ref
                            .read(availabilityNotifierProvider.notifier)
                            .clearSlots();
                        _fetchSlots();
                      },
                validator: (value) =>
                    value == null ? 'Doctor is required' : null,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Branch ─────────────────────────────────────
            _fieldLabel('Branch', required: true),
            branchesAsync.when(
              loading: () => const LinearProgressIndicator(color: AppColors.primary),
              error: (error, _) => Text(
                'Failed to load branches: $error',
                style: const TextStyle(color: AppColors.error),
              ),
              data: (branches) => DropdownButtonFormField<int>(
                initialValue: _branchId,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Select Branch',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: (branches as List).map((branch) {
                  return DropdownMenuItem<int>(
                    value: branch.id,
                    child: Text(branch.name),
                  );
                }).toList(),
                onChanged: lockClinicians
                    ? null
                    : (value) {
                        setState(() => _branchId = value);
                        ref
                            .read(availabilityNotifierProvider.notifier)
                            .clearSlots();
                        _fetchSlots();
                      },
                validator: (value) =>
                    value == null ? 'Branch is required' : null,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Patient ────────────────────────────────────
            if (canCreateForOthers) ...[
              _fieldLabel('Patient', required: true),
              PatientSearchField(
                selectedPatientId: _userId,
                selectedPatientName: _selectedPatientName,
                onPatientSelected: (PatientModel? patient) {
                  setState(() {
                    _userId = patient?.userId;
                    _selectedPatientName = patient?.name;
                  });
                },
              ),
            ] else ...[
              _fieldLabel('Patient'),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        currentUser?.name ?? 'Current user',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Reason ─────────────────────────────────────
            _fieldLabel('Reason for Visit'),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'e.g., Toothache, Cleaning, Check-up',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Section: Schedule ─────────────────────────
            _sectionTitle('Schedule'),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Date ───────────────────────────────────────
            _fieldLabel('Date', required: true),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedDate != null
                              ? AppColors.ink
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Time Slots ─────────────────────────────────
            if (_selectedDate != null) ...[
              _fieldLabel('Available Time Slots', required: true),
              TimeSlotPicker(
                state: availState,
                onSlotSelected: (slot) {
                  ref
                      .read(availabilityNotifierProvider.notifier)
                      .selectSlot(slot);
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
            ],

            // ── Status (edit only) ─────────────────────────
            if (_isEditing && canUpdateStatus) ...[
              _sectionTitle('Status'),
              const SizedBox(height: AppDimensions.paddingMedium),
              _fieldLabel('Appointment Status'),
              DropdownButtonFormField<String>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (value) {
                  setState(() => _status = value ?? 'pending');
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
            ],

            const SizedBox(height: AppDimensions.paddingSmall),

            // ── Submit Button ──────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Icon(_isEditing
                        ? Icons.save_outlined
                        : Icons.event_available_rounded),
                label: Text(
                  _isEditing ? 'Update Appointment' : 'Book Appointment',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingSmall),

            // ── Cancel Button ──────────────────────────────
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable widgets ─────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}