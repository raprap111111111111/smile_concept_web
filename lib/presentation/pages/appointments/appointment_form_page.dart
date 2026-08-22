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
import '../../theme/app_theme.dart';
import 'widgets/patient_search_field.dart';
import 'widgets/time_slot_picker.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

enum StaffPatientBookingType { registered, walkInGuest }

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

  // Walk-in / Guest controllers
  final _walkInNameController = TextEditingController();
  final _walkInPhoneController = TextEditingController();
  final _walkInEmailController = TextEditingController();
  final _dependentNameController = TextEditingController();

  StaffPatientBookingType _bookingType = StaffPatientBookingType.registered;
  String _bookingFor = 'Self / Patient'; // 'Self / Patient' or 'Child / Dependent'

  int? _doctorId;
  int? _branchId;
  int? _userId;
  String? _selectedPatientName;
  DateTime? _selectedDate;
  String _status = 'pending';

  bool _isSubmitting = false;
  bool get _isEditing => widget.existingAppointment != null;

  static InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

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

      if (appointment.reasonForVisit != null) {
        final reason = appointment.reasonForVisit!;
        if (reason.contains('[Booking For:')) {
          final regex = RegExp(r'\[Booking For: (.*?)\]');
          final match = regex.firstMatch(reason);
          if (match != null) {
            final content = match.group(1) ?? '';
            if (content.contains('-')) {
              final parts = content.split('-');
              _bookingFor = 'Child / Dependent';
              _dependentNameController.text = parts.last.trim();
            } else {
              _bookingFor = content.trim();
            }
            _reasonController.text = reason.replaceAll(regex, '').trim();
          }
        } else {
          _reasonController.text = reason;
        }
      }
    }

    Future.microtask(() {
      if (mounted) {
        ref.read(availabilityNotifierProvider.notifier).clearSlots();
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _walkInNameController.dispose();
    _walkInPhoneController.dispose();
    _walkInEmailController.dispose();
    _dependentNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    if (_doctorId == null || _branchId == null || _selectedDate == null) return;
    await ref.read(availabilityNotifierProvider.notifier).fetchSlots(
          doctorId: _doctorId!,
          branchId: _branchId!,
          date: _selectedDate!,
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    final canCreateForOthers = permissionService.can(Perm.appointmentCreateForOthers);
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

    // Validation for registered patient mode
    if (!_isEditing && canCreateForOthers && _bookingType == StaffPatientBookingType.registered && _userId == null) {
      _showError('Please select a registered patient account.');
      return;
    }

    // Validation for walk-in mode
    if (!_isEditing && canCreateForOthers && _bookingType == StaffPatientBookingType.walkInGuest && _walkInNameController.text.trim().isEmpty) {
      _showError("Please enter the walk-in patient's full name.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(appointmentRepositoryProvider);
      AppointmentModel result;

      // Package reason and dependent details
      String? finalReason = _reasonController.text.trim();
      if (_bookingFor != 'Self / Patient') {
        final dep = _dependentNameController.text.trim();
        final tag = dep.isNotEmpty ? 'Child / Minor - $dep' : 'Child / Minor';
        finalReason = '[Booking For: $tag] $finalReason'.trim();
      }
      if (finalReason.isEmpty) finalReason = null;

      if (_isEditing) {
        final existing = widget.existingAppointment!;
        final targetUserId = canCreateForOthers ? (_userId ?? existing.userId) : existing.userId;

        final request = AppointmentRequest(
          doctorId: _doctorId ?? existing.doctorId,
          branchId: _branchId ?? existing.branchId,
          startTime: selectedSlot != null ? selectedSlot.startDateTime : existing.startTime,
          endTime: selectedSlot != null ? selectedSlot.endDateTime : existing.endTime,
          userId: targetUserId,
          status: canUpdateStatus ? _status : existing.status.name,
          reasonForVisit: finalReason,
        );

        result = await repo.updateAppointment(id: existing.id, request: request);
      } else {
        final isWalkIn = _bookingType == StaffPatientBookingType.walkInGuest;

        final request = AppointmentRequest(
          doctorId: _doctorId!,
          branchId: _branchId!,
          startTime: selectedSlot!.startDateTime,
          endTime: selectedSlot.endDateTime,
          userId: isWalkIn ? null : (canCreateForOthers ? _userId : currentUser?.id),
          patientName: isWalkIn ? _walkInNameController.text.trim() : null,
          patientPhone: isWalkIn ? _walkInPhoneController.text.trim() : null,
          patientEmail: isWalkIn ? _walkInEmailController.text.trim() : null,
          status: _status,
          reasonForVisit: finalReason,
        );

        result = await repo.createAppointment(request);
      }

      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError(describeError(error));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final availState = ref.watch(availabilityNotifierProvider);
    final doctorsAsync = ref.watch(doctorsProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final permissionService = ref.watch(permissionServiceProvider);
    final currentUser = ref.watch(authStateProvider).user;

    final canCreateForOthers = permissionService.can(Perm.appointmentCreateForOthers);
    final canUpdateStatus = permissionService.can(Perm.appointmentUpdateStatus);
    final lockClinicians = _isEditing && !permissionService.can(Perm.appointmentUpdate);

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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
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
                Text(
                  _isEditing ? 'Update patient booking details' : 'Book a new patient appointment',
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
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Patient Information'),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── STAFF PATIENT SELECTION ──────────────────────────
            if (canCreateForOthers) ...[
              // Mode Selector: Registered vs Walk-In
              Row(
                children: [
                  Expanded(
                    child: _ChoiceCard(
                      title: 'Registered Patient',
                      subtitle: 'Search existing patient account',
                      icon: Icons.badge_outlined,
                      selected: _bookingType == StaffPatientBookingType.registered,
                      onTap: () => setState(() => _bookingType = StaffPatientBookingType.registered),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceCard(
                      title: 'Walk-In / Guest',
                      subtitle: 'Type new patient details',
                      icon: Icons.directions_walk_outlined,
                      selected: _bookingType == StaffPatientBookingType.walkInGuest,
                      onTap: () => setState(() => _bookingType = StaffPatientBookingType.walkInGuest),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              // Mode 1: Registered Patient Search
              if (_bookingType == StaffPatientBookingType.registered) ...[
                _fieldLabel('Search Registered Patient', required: true),
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
              ],

              // Mode 2: Walk-In / Unregistered Patient Inputs
              if (_bookingType == StaffPatientBookingType.walkInGuest) ...[
                _fieldLabel('Patient Full Name', required: true),
                TextFormField(
                  controller: _walkInNameController,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: _inputDeco('e.g. Juan Dela Cruz', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Patient name is required' : null,
                ),
                const SizedBox(height: AppDimensions.paddingSmall),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Mobile Number'),
                          TextFormField(
                            controller: _walkInPhoneController,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                            decoration: _inputDeco('09XX XXX XXXX', Icons.phone_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Email Address'),
                          TextFormField(
                            controller: _walkInEmailController,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                            decoration: _inputDeco('patient@email.com', Icons.mail_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppDimensions.paddingMedium),

              // Attendance Option: Self vs Minor / Child
              _fieldLabel('Who is attending this appointment?', required: true),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceCard(
                      title: 'Self / Adult',
                      subtitle: 'Patient attends for themselves',
                      icon: Icons.person_outline,
                      selected: _bookingFor == 'Self / Patient',
                      onTap: () => setState(() => _bookingFor = 'Self / Patient'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceCard(
                      title: 'Child / Dependent',
                      subtitle: 'Parent books for minor',
                      icon: Icons.family_restroom_outlined,
                      selected: _bookingFor != 'Self / Patient',
                      onTap: () => setState(() => _bookingFor = 'Child / Dependent'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_bookingFor != 'Self / Patient') ...[
                _fieldLabel("Child / Dependent's Full Name"),
                TextFormField(
                  controller: _dependentNameController,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: _inputDeco("e.g. Timmy Dela Cruz", Icons.child_care_outlined),
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
              ],
            ],

            const SizedBox(height: AppDimensions.paddingLarge),
            _sectionTitle('Clinic & Schedule'),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Doctor ─────────────────────────────────────
            _fieldLabel('Doctor', required: true),
            doctorsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Error loading doctors', style: TextStyle(color: Colors.red)),
              data: (doctors) => DropdownButtonFormField<int>(
                initialValue: _doctorId,
                dropdownColor: AppColors.surface,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                iconEnabledColor: AppColors.textSecondary,
                isExpanded: true,
                decoration: _inputDeco('Select Doctor', Icons.medical_services_outlined),
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
                        ref.read(availabilityNotifierProvider.notifier).clearSlots();
                        _fetchSlots();
                      },
                validator: (value) => value == null ? 'Doctor is required' : null,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Branch ─────────────────────────────────────
            _fieldLabel('Branch', required: true),
            branchesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Error loading branches', style: TextStyle(color: Colors.red)),
              data: (branches) => DropdownButtonFormField<int>(
                initialValue: _branchId,
                dropdownColor: AppColors.surface,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                iconEnabledColor: AppColors.textSecondary,
                isExpanded: true,
                decoration: _inputDeco('Select Branch', Icons.location_on_outlined),
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
                        ref.read(availabilityNotifierProvider.notifier).clearSlots();
                        _fetchSlots();
                      },
                validator: (value) => value == null ? 'Branch is required' : null,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Reason ─────────────────────────────────────
            _fieldLabel('Reason for Visit'),
            TextFormField(
              controller: _reasonController,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              maxLines: 2,
              maxLength: 500,
              decoration: _inputDeco('e.g., Toothache, Cleaning, Check-up', Icons.notes_rounded),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Date ───────────────────────────────────────
            _fieldLabel('Date', required: true),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedDate != null ? AppColors.textPrimary : AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            if (_selectedDate != null) ...[
              _fieldLabel('Available Time Slots', required: true),
              TimeSlotPicker(
                state: availState,
                onSlotSelected: (slot) {
                  ref.read(availabilityNotifierProvider.notifier).selectSlot(slot);
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
            ],

            if (_isEditing && canUpdateStatus) ...[
              _sectionTitle('Status'),
              const SizedBox(height: AppDimensions.paddingMedium),
              _fieldLabel('Appointment Status'),
              DropdownButtonFormField<String>(
                initialValue: _status,
                dropdownColor: AppColors.surface,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                iconEnabledColor: AppColors.textSecondary,
                isExpanded: true,
                decoration: _inputDeco('Status', Icons.flag_outlined),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (value) => setState(() => _status = value ?? 'pending'),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
            ],

            const SizedBox(height: AppDimensions.paddingSmall),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_isEditing ? Icons.save_outlined : Icons.event_available_rounded),
                label: Text(_isEditing ? 'Update Appointment' : 'Book Appointment', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark)),
      ],
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(text, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
          if (required) const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentLight : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 20),
                  const Spacer(),
                  Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: selected ? AppColors.primary : AppColors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}