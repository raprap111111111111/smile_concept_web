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
import '../doctor_schedules/widgets/dropdown_states.dart';
import 'widgets/patient_search_field.dart';
import 'widgets/time_slot_picker.dart';

final selectedDoctorProvider = StateProvider<int?>((ref) => null);
final selectedBranchProvider = StateProvider<int?>((ref) => null);
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

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
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  int? _selectedPatientId;
  String? _selectedPatientName;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authStateProvider).user;
    _fullNameController.text = currentUser?.name ?? '';
    _mobileController.text = currentUser?.phone ?? '';
    _emailController.text = currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
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

    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
      ref.read(availabilityNotifierProvider.notifier).clearSlots();
      await _fetchSlots();
    }
  }

  Future<void> _bookAppointment(TimeSlot slot) async {
    if (!_formKey.currentState!.validate()) return;

    final doctorId = ref.read(selectedDoctorProvider);
    final branchId = ref.read(selectedBranchProvider);
    final date = ref.read(selectedDateProvider);

    final permissionService = ref.read(permissionServiceProvider);
    final currentUser = ref.read(authStateProvider).user;

    final canCreateSelf = permissionService.can(Perm.appointmentCreate);
    final canCreateForOthers =
        permissionService.can(Perm.appointmentCreateForOthers);

    if (!canCreateSelf && !canCreateForOthers) {
      _showError('You do not have permission to book appointments.');
      return;
    }

    if (doctorId == null || branchId == null || date == null) return;

    if (canCreateForOthers && _selectedPatientId == null) {
      _showError('Please select a patient.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(appointmentRepositoryProvider);

      final startDateTime = DateTime(
        date.year, date.month, date.day,
        slot.startDateTime.hour, slot.startDateTime.minute,
      );

      final endDateTime = DateTime(
        date.year, date.month, date.day,
        slot.endDateTime.hour, slot.endDateTime.minute,
      );

      final request = AppointmentRequest(
        doctorId: doctorId,
        branchId: branchId,
        startTime: startDateTime,
        endTime: endDateTime,
        status: 'pending',
        userId: canCreateForOthers ? _selectedPatientId : currentUser?.id,
        patientName: _fullNameController.text.trim(),
        patientPhone: _mobileController.text.trim(),
        patientEmail: _emailController.text.trim(),
        reasonForVisit: _reasonController.text.trim(),
        additionalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final result = await repo.createAppointment(request);
      ref.read(appointmentNotifierProvider.notifier).addAppointment(result);

      if (mounted) {
        _showSuccess('Appointment created successfully.');
        Navigator.of(context).pop(result);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Failed to book: $error');
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

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
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
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlot = availState.selectedSlot;

    final permissionService = ref.watch(permissionServiceProvider);
    final canCreateForOthers =
        permissionService.can(Perm.appointmentCreateForOthers);

    return Scaffold(
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
                  _buildHeader(),
                  const SizedBox(height: AppDimensions.paddingLarge),
                  _buildFormCard(
                    availState: availState,
                    selectedDate: selectedDate,
                    selectedSlot: selectedSlot,
                    canCreateForOthers: canCreateForOthers,
                  ),
                ],
              ),
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
            child: const Icon(
              Icons.event_available_rounded,
              color: AppColors.textOnPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book Appointment', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  'Fill in the details below to schedule a visit',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── FORM CARD ──────────────────────────────────────────────
  Widget _buildFormCard({
    required dynamic availState,
    required DateTime? selectedDate,
    required TimeSlot? selectedSlot,
    required bool canCreateForOthers,
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
            // ── Patient Info Section ─────────────────────
            _sectionTitle('Patient Information'),
            const SizedBox(height: AppDimensions.paddingMedium),

            _fieldLabel('Full Name', required: true),
            TextFormField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.validateName(
                value,
                fieldName: 'Full name',
              ),
              decoration: const InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            _fieldLabel('Mobile Number', required: true),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final requiredError = Validators.required(
                  value,
                  fieldName: 'Mobile number',
                );
                if (requiredError != null) return requiredError;
                return Validators.validatePhone(value);
              },
              decoration: const InputDecoration(
                hintText: 'e.g., 0917-000-0000',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            _fieldLabel('Email', required: true),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.validateEmail,
              decoration: const InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Appointment Details Section ─────────────
            _sectionTitle('Appointment Details'),
            const SizedBox(height: AppDimensions.paddingMedium),

            _fieldLabel('Doctor', required: true),
            _buildDoctorField(),
            const SizedBox(height: AppDimensions.paddingMedium),

            _fieldLabel('Branch', required: true),
            _buildBranchField(),
            const SizedBox(height: AppDimensions.paddingMedium),

            if (canCreateForOthers) ...[
              _fieldLabel('Patient', required: true),
              PatientSearchField(
                selectedPatientId: _selectedPatientId,
                selectedPatientName: _selectedPatientName,
                onPatientSelected: (PatientModel? patient) {
                  setState(() {
                    _selectedPatientId = patient?.userId;
                    _selectedPatientName = patient?.name;
                  });
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
            ],

            _fieldLabel('Appointment Date', required: true),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
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
                        selectedDate == null
                            ? 'Select date'
                            : DateFormat('EEE, MMM dd yyyy')
                                .format(selectedDate),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: selectedDate != null
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

            _fieldLabel('Purpose of Visit', required: true),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 500,
              validator: (value) => Validators.required(
                value,
                fieldName: 'Purpose of visit',
              ),
              decoration: const InputDecoration(
                hintText: 'e.g., Toothache, Cleaning, Check-up',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            _fieldLabel('Additional Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Anything else the team should know?',
                prefixIcon: Icon(Icons.note_add_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Time Slots Section ──────────────────────
            _sectionTitle('Appointment Time'),
            const SizedBox(height: AppDimensions.paddingMedium),

            if (selectedDate == null)
              _infoBanner(
                'Please select a date first to see available time slots.',
                icon: Icons.info_outline_rounded,
              )
            else if (availState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (availState.error != null)
              _infoBanner(
                'Error loading slots: ${availState.error}',
                icon: Icons.error_outline_rounded,
                isError: true,
              )
            else if (availState.slots.isEmpty)
              _infoBanner(
                'No slots available for this date.\nTry selecting a different date.',
                icon: Icons.event_busy_rounded,
              )
            else
              TimeSlotPicker(
                state: availState,
                onSlotSelected: (slot) {
                  ref
                      .read(availabilityNotifierProvider.notifier)
                      .selectSlot(slot);
                },
              ),

            const SizedBox(height: AppDimensions.paddingXL),

            // ── Submit Button ───────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: (selectedSlot == null || _isSubmitting)
                    ? null
                    : () => _bookAppointment(selectedSlot),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
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
                    : const Icon(Icons.event_available_rounded),
                label: Text(
                  _isSubmitting ? 'Booking...' : 'Book Appointment',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),

            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
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

  Widget _buildDoctorField() {
    final doctorsAsync = ref.watch(doctorsListProvider);
    final selected = ref.watch(selectedDoctorProvider);

    return doctorsAsync.when(
      loading: () => const DropdownSkeleton(label: 'Loading doctors...'),
      error: (error, _) => DropdownError(
        message: 'Failed to load doctors: $error',
      ),
      data: (doctors) => DropdownButtonFormField<int>(
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Select Doctor',
          prefixIcon: Icon(Icons.medical_services_outlined),
        ),
        items: doctors.map((doctor) {
          return DropdownMenuItem<int>(
            value: doctor.id,
            child: Text(
              doctor.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (id) {
          ref.read(selectedDoctorProvider.notifier).state = id;
          ref.read(availabilityNotifierProvider.notifier).clearSlots();
          _fetchSlots();
        },
      ),
    );
  }

  Widget _buildBranchField() {
    final branchesAsync = ref.watch(branchesListProvider);
    final selected = ref.watch(selectedBranchProvider);

    return branchesAsync.when(
      loading: () => const DropdownSkeleton(label: 'Loading branches...'),
      error: (error, _) => DropdownError(
        message: 'Failed to load branches: $error',
      ),
      data: (branches) => DropdownButtonFormField<int>(
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Select Branch',
          prefixIcon: Icon(Icons.location_on_outlined),
        ),
        items: branches.map((branch) {
          return DropdownMenuItem<int>(
            value: branch.id,
            child: Text(
              branch.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (id) {
          ref.read(selectedBranchProvider.notifier).state = id;
          ref.read(availabilityNotifierProvider.notifier).clearSlots();
          _fetchSlots();
        },
      ),
    );
  }

  Widget _infoBanner(
    String message, {
    IconData icon = Icons.info_outline_rounded,
    bool isError = false,
  }) {
    final color = isError ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: isError ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

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