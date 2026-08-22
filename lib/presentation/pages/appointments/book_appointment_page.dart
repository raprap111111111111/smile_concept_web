// lib/presentation/pages/appointments/book_appointment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/appointment/appointment_request.dart';
import '../../../data/models/appointment/availability_model.dart';
import '../../../data/models/patient/patient_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../providers/appointment/appointment_provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/doctor_schedule/schedule_form_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../doctor_schedules/widgets/dropdown_states.dart';
import 'widgets/patient_search_field.dart';
import 'widgets/time_slot_picker.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

final selectedDoctorProvider = StateProvider<int?>((ref) => null);
final selectedBranchProvider = StateProvider<int?>((ref) => null);
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

enum BookingRelation { self, guardianMinor }

class BookAppointmentPage extends ConsumerStatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  ConsumerState<BookAppointmentPage> createState() =>
      _BookAppointmentPageState();
}

class _BookAppointmentPageState extends ConsumerState<BookAppointmentPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _childNameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  /// null until user picks — forces them to choose first
  BookingRelation? _relation;

  int? _selectedPatientId;
  String? _selectedPatientName;

  static InputDecoration _deco(String hint, IconData icon, {bool locked = false}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      suffixIcon: locked
          ? const Icon(Icons.lock_outline, size: 18, color: AppColors.textTertiary)
          : null,
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
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
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _childNameController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isStaff {
    return ref.read(permissionServiceProvider).can(Perm.appointmentCreateForOthers);
  }

  void _applyLoggedInUserAsGuardianOrSelf() {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;
    _fullNameController.text = user.name;
    _mobileController.text = user.phone ?? '';
    _emailController.text = user.email;
  }

  void _onRelationPicked(BookingRelation r) {
    setState(() {
      _relation = r;
      _childNameController.clear();

      if (!_isStaff) {
        // Patient portal: logged-in user is always the account / guardian contact
        _applyLoggedInUserAsGuardianOrSelf();
      } else if (r == BookingRelation.self && _selectedPatientName != null) {
        _fullNameController.text = _selectedPatientName!;
      }
    });
  }

  Future<void> _fetchSlots() async {
    final doctorId = ref.read(selectedDoctorProvider);
    final branchId = ref.read(selectedBranchProvider);
    final date = ref.read(selectedDateProvider);
    if (doctorId == null || branchId == null || date == null) return;

    await ref.read(availabilityNotifierProvider.notifier).fetchSlots(
          doctorId: doctorId,
          branchId: branchId,
          date: date,
        );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedDateProvider) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    ref.read(selectedDateProvider.notifier).state = picked;
    ref.read(availabilityNotifierProvider.notifier).clearSlots();
    await _fetchSlots();
  }

  Future<void> _bookAppointment(TimeSlot slot) async {
    if (_relation == null) {
      _showError('Please choose Self / Patient or Guardian / Minor first.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final doctorId = ref.read(selectedDoctorProvider);
    final branchId = ref.read(selectedBranchProvider);
    final date = ref.read(selectedDateProvider);
    final currentUser = ref.read(authStateProvider).user;
    final canCreateForOthers = _isStaff;

    if (doctorId == null || branchId == null || date == null) return;

    if (canCreateForOthers && _selectedPatientId == null) {
      _showError('Please select a patient account.');
      return;
    }

    if (_relation == BookingRelation.guardianMinor &&
        _childNameController.text.trim().isEmpty) {
      _showError("Please enter the child / minor's full name.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final startDateTime = DateTime(
        date.year, date.month, date.day,
        slot.startDateTime.hour, slot.startDateTime.minute,
      );
      final endDateTime = DateTime(
        date.year, date.month, date.day,
        slot.endDateTime.hour, slot.endDateTime.minute,
      );

      final isGuardian = _relation == BookingRelation.guardianMinor;

      // Attendee name on the calendar
      final attendeeName = isGuardian
          ? _childNameController.text.trim()
          : _fullNameController.text.trim();

      String? reason = _reasonController.text.trim();
      if (reason.isEmpty) reason = null;
      if (isGuardian) {
        final child = _childNameController.text.trim();
        reason =
            '[Booking For: Child / Minor${child.isEmpty ? '' : ' - $child'}] ${reason ?? ''}'
                .trim();
      }

      final request = AppointmentRequest(
        doctorId: doctorId,
        branchId: branchId,
        startTime: startDateTime,
        endTime: endDateTime,
        status: 'pending',
        // Account owner = patient user (staff) OR logged-in guardian/patient
        userId: canCreateForOthers ? _selectedPatientId : currentUser?.id,
        patientName: attendeeName,
        patientPhone: _mobileController.text.trim(),
        patientEmail: _emailController.text.trim(),
        reasonForVisit: reason,
        additionalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final result =
          await ref.read(appointmentRepositoryProvider).createAppointment(request);
      ref.read(appointmentNotifierProvider.notifier).addAppointment(result);

      if (!mounted) return;
      _showSuccess('Appointment created successfully.');
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError(describeError(e, fallback: 'Failed to book'));
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

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: AppDimensions.paddingLarge),
                    _formBody(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
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
            child: const Icon(Icons.event_available_rounded,
                color: AppColors.textOnPrimary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book Appointment', style: AppTextStyles.headlineSmall),
                Text(
                  'First choose: Patient or Guardian',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _formBody() {
    final availState = ref.watch(availabilityNotifierProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlot = availState.selectedSlot;
    final staff = ref.watch(permissionServiceProvider).can(Perm.appointmentCreateForOthers);

    final hasRelation = _relation != null;
    final isSelf = _relation == BookingRelation.self;
    final isGuardian = _relation == BookingRelation.guardianMinor;

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
            // ═══════════════════════════════════════════════════
            // STEP 0 — FIRST THING USER SEES (like consent)
            // ═══════════════════════════════════════════════════
            _sectionTitle('Who is this appointment for?'),
            const SizedBox(height: 8),
            Text(
              'Choose one before filling the rest of the form.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _RelationCard(
                    title: 'Self / Patient',
                    subtitle: 'I am the patient attending',
                    icon: Icons.person_outline,
                    selected: isSelf,
                    onTap: () => _onRelationPicked(BookingRelation.self),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RelationCard(
                    title: 'Guardian / Minor',
                    subtitle: 'I am parent/guardian booking for a child',
                    icon: Icons.family_restroom_outlined,
                    selected: isGuardian,
                    onTap: () => _onRelationPicked(BookingRelation.guardianMinor),
                  ),
                ),
              ],
            ),

            // Rest of form only after choice (same UX as consent step 0 → step 1)
            if (!hasRelation) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select Self / Patient or Guardian / Minor to continue.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (hasRelation) ...[
              const SizedBox(height: 28),
              _sectionTitle('Patient details'),
              const SizedBox(height: 12),

              // Staff: which account owns the booking
              if (staff) ...[
                _fieldLabel(
                  isGuardian
                      ? 'Parent / guardian patient account'
                      : 'Patient account',
                  required: true,
                ),
                PatientSearchField(
                  selectedPatientId: _selectedPatientId,
                  selectedPatientName: _selectedPatientName,
                  onPatientSelected: (PatientModel? p) {
                    setState(() {
                      _selectedPatientId = p?.userId;
                      _selectedPatientName = p?.name;
                      if (p == null) return;
                      if (isSelf) {
                        _fullNameController.text = p.name;
                      } else {
                        // guardian contact from account
                        _fullNameController.text = p.name;
                      }
                      if ((p.phone ?? '').isNotEmpty) {
                        _mobileController.text = p.phone!;
                      }
                      if (p.email.isNotEmpty) {
                        _emailController.text = p.email;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // SELF
              if (isSelf) ...[
                _fieldLabel('Patient full name', required: true),
                TextFormField(
                  controller: _fullNameController,
                  readOnly: !staff, // patient locks own name
                  style: AppTextStyles.inputText,
                  validator: (v) =>
                      Validators.validateName(v, fieldName: 'Full name'),
                  decoration: _deco(
                    staff ? 'Patient full name' : 'Loaded from your profile',
                    Icons.person_outline,
                    locked: !staff,
                  ),
                ),
                if (!staff)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      '🔒 Locked — you are the patient.',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
              ],

              // GUARDIAN
              if (isGuardian) ...[
                _fieldLabel("Child / minor's full name", required: true),
                TextFormField(
                  controller: _childNameController,
                  style: AppTextStyles.inputText,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Enter the child's full name"
                      : null,
                  decoration: _deco(
                    'e.g. Timmy Dela Cruz',
                    Icons.child_care_outlined,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, bottom: 12),
                  child: Text(
                    'Child has no account. Parent/guardian account holds this booking.',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                _fieldLabel('Parent / guardian name', required: true),
                TextFormField(
                  controller: _fullNameController,
                  readOnly: !staff,
                  style: AppTextStyles.inputText,
                  validator: (v) =>
                      Validators.validateName(v, fieldName: 'Guardian name'),
                  decoration: _deco(
                    'Parent / guardian full name',
                    Icons.family_restroom,
                    locked: !staff,
                  ),
                ),
              ],

              const SizedBox(height: 12),
              _fieldLabel(
                isGuardian ? 'Guardian mobile' : 'Mobile number',
                required: true,
              ),
              TextFormField(
                controller: _mobileController,
                style: AppTextStyles.inputText,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final req =
                      Validators.required(value, fieldName: 'Mobile number');
                  if (req != null) return req;
                  return Validators.validatePhone(value);
                },
                decoration: _deco('e.g., 0917-000-0000', Icons.phone_outlined),
              ),
              const SizedBox(height: 12),
              _fieldLabel(
                isGuardian ? 'Guardian email' : 'Email',
                required: true,
              ),
              TextFormField(
                controller: _emailController,
                style: AppTextStyles.inputText,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
                decoration: _deco('name@example.com', Icons.email_outlined),
              ),

              const SizedBox(height: 28),
              _sectionTitle('Appointment details'),
              const SizedBox(height: 12),

              _fieldLabel('Doctor', required: true),
              _doctorField(),
              const SizedBox(height: 12),
              _fieldLabel('Branch', required: true),
              _branchField(),
              const SizedBox(height: 12),

              _fieldLabel('Date', required: true),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Select date'
                              : DateFormat('EEE, MMM dd yyyy')
                                  .format(selectedDate),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selectedDate != null
                                ? AppColors.ink
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _fieldLabel('Purpose of visit', required: true),
              TextFormField(
                controller: _reasonController,
                style: AppTextStyles.inputText,
                maxLines: 2,
                maxLength: 500,
                validator: (v) =>
                    Validators.required(v, fieldName: 'Purpose of visit'),
                decoration: _deco(
                    'e.g., Cleaning, Check-up', Icons.notes_outlined),
              ),
              const SizedBox(height: 12),

              _fieldLabel('Additional notes'),
              TextFormField(
                controller: _notesController,
                style: AppTextStyles.inputText,
                maxLines: 3,
                maxLength: 1000,
                decoration: _deco(
                    'Optional notes…', Icons.note_add_outlined),
              ),

              const SizedBox(height: 24),
              _sectionTitle('Time'),
              const SizedBox(height: 12),

              if (selectedDate == null)
                _banner('Select a date to load time slots.')
              else if (availState.isLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ))
              else if (availState.error != null)
                _banner('Error: ${availState.error}', error: true)
              else if (availState.slots.isEmpty)
                _banner('No slots for this date.')
              else
                TimeSlotPicker(
                  state: availState,
                  onSlotSelected: (slot) {
                    ref
                        .read(availabilityNotifierProvider.notifier)
                        .selectSlot(slot);
                  },
                ),

              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: (selectedSlot == null || _isSubmitting)
                      ? null
                      : () => _bookAppointment(selectedSlot),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.event_available_rounded),
                  label: Text(
                    _isSubmitting ? 'Booking…' : 'Book Appointment',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _doctorField() {
    final async = ref.watch(doctorsListProvider);
    final selected = ref.watch(selectedDoctorProvider);
    return async.when(
      loading: () => const DropdownSkeleton(label: 'Loading doctors...'),
      error: (e, _) => DropdownError(
          message: describeError(e, fallback: 'Failed to load doctors')),
      data: (doctors) => DropdownButtonFormField<int>(
        initialValue: selected,
        dropdownColor: AppColors.surface,
        style: AppTextStyles.inputText,
        isExpanded: true,
        decoration: _deco('Select doctor', Icons.medical_services_outlined),
        items: doctors
            .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
            .toList(),
        onChanged: (id) {
          ref.read(selectedDoctorProvider.notifier).state = id;
          ref.read(availabilityNotifierProvider.notifier).clearSlots();
          _fetchSlots();
        },
        validator: (v) => v == null ? 'Doctor is required' : null,
      ),
    );
  }

  Widget _branchField() {
    final async = ref.watch(branchesListProvider);
    final selected = ref.watch(selectedBranchProvider);
    return async.when(
      loading: () => const DropdownSkeleton(label: 'Loading branches...'),
      error: (e, _) => DropdownError(
          message: describeError(e, fallback: 'Failed to load branches')),
      data: (branches) => DropdownButtonFormField<int>(
        initialValue: selected,
        dropdownColor: AppColors.surface,
        style: AppTextStyles.inputText,
        isExpanded: true,
        decoration: _deco('Select branch', Icons.location_on_outlined),
        items: branches
            .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
            .toList(),
        onChanged: (id) {
          ref.read(selectedBranchProvider.notifier).state = id;
          ref.read(availabilityNotifierProvider.notifier).clearSlots();
          _fetchSlots();
        },
        validator: (v) => v == null ? 'Branch is required' : null,
      ),
    );
  }

  Widget _sectionTitle(String t) => Row(
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
          Text(t,
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primaryDark)),
        ],
      );

  Widget _fieldLabel(String t, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(t,
                style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.ink, fontWeight: FontWeight.w700)),
            if (required)
              const Text(' *',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _banner(String m, {bool error = false}) {
    final c = error ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Text(m, style: AppTextStyles.bodySmall.copyWith(color: c)),
    );
  }
}

class _RelationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RelationCard({
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  )),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}