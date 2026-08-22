// lib/presentation/pages/appointments/appointment_form_patient.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/appointment/appointment_request.dart';
import '../../../data/models/appointment/availability_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/doctor_repository.dart';
import '../../providers/appointment/appointment_provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/branch/branch_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'widgets/booking_calendar.dart';
import 'widgets/patient_form_layout.dart';
import 'widgets/patient_slot_picker.dart';

class AppointmentFormPatient extends ConsumerStatefulWidget {
  const AppointmentFormPatient({super.key});

  @override
  ConsumerState<AppointmentFormPatient> createState() =>
      _AppointmentFormPatientState();
}

class _AppointmentFormPatientState
    extends ConsumerState<AppointmentFormPatient> {
  static const int _typicalDurationMinutes = 30;
  static const double _formMaxWidth = 720;
  static const TextStyle _inputTextStyle =
      TextStyle(color: AppColors.textPrimary, fontSize: 14);

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  late DateTime _visibleMonth;
  Map<String, int> _dayLoad = {};
  bool _isLoadingDayLoad = false;
  int _dayLoadRequestId = 0;

  String? _purpose;
  String _bookingFor = 'Myself'; // 'Myself' or 'Child / Dependent'
  String _relationship = 'Child / Minor';

  int? _doctorId;
  int? _branchId;

  bool _isSubmitting = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final List<String> _purposes = [
    'Dental Check-up',
    'Teeth Cleaning',
    'Tooth Extraction',
    'Root Canal',
    'Braces Consultation',
    'Dental Filling',
    'Teeth Whitening',
    'Emergency',
    'Other',
  ];

  final List<String> _relationships = [
    'Child / Minor',
    'Spouse',
    'Parent',
    'Other Dependent',
  ];

  static InputDecoration _inputDeco(String hint, IconData icon, {bool readOnly = false}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      suffixIcon: readOnly ? const Icon(Icons.lock_outline, size: 18, color: AppColors.textTertiary) : null,
      filled: true,
      fillColor: readOnly ? AppColors.surface : AppColors.surface,
      isDense: true,
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
    _applyAccountDetails();

    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _loadDayLoad();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(availabilityNotifierProvider.notifier).clearSlots();
    });
  }

  void _applyAccountDetails() {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;
    _fullNameController.text = user.name;
    _emailController.text = user.email;
    _mobileController.text = user.phone ?? '';
  }

  void _onBookingForChanged(String option) {
    setState(() {
      _bookingFor = option;

      if (option == 'Myself') {
        _applyAccountDetails();
      } else {
        // Booking for Child/Dependent -> Clear name so parent types the child's name!
        _fullNameController.clear();
        // Keep phone/email for contact
      }
    });
  }

  Future<void> _fetchSlots() async {
    if (_doctorId == null || _branchId == null || _selectedDate == null) return;
    await ref.read(availabilityNotifierProvider.notifier).fetchSlots(
          doctorId: _doctorId!,
          branchId: _branchId!,
          date: _selectedDate!,
        );
  }

  Future<void> _reloadSlots() async {
    ref.read(availabilityNotifierProvider.notifier).clearSlots();
    await _fetchSlots();
  }

  Future<void> _loadDayLoad() async {
    final requestId = ++_dayLoadRequestId;
    setState(() => _isLoadingDayLoad = true);

    try {
      final load = await ref.read(appointmentRepositoryProvider).getClinicDayLoad(
            month: _visibleMonth,
            branchId: _branchId,
            doctorId: _doctorId,
          );

      if (!mounted || requestId != _dayLoadRequestId) return;
      setState(() {
        _dayLoad = load;
        _isLoadingDayLoad = false;
      });
    } catch (_) {
      if (!mounted || requestId != _dayLoadRequestId) return;
      setState(() {
        _dayLoad = {};
        _isLoadingDayLoad = false;
      });
    }
  }

  void _onMonthChanged(DateTime month) {
    setState(() => _visibleMonth = month);
    _loadDayLoad();
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    _reloadSlots();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _onSelectedDate(DateTime slotTime) {
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      slotTime.hour,
      slotTime.minute,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return;
    }

    if (_doctorId == null || _branchId == null) return;
    final slot = ref.read(availabilityNotifierProvider).selectedSlot;
    if (slot == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Append Guardian / Dependent context if applicable
      String? notes = _notesController.text.trim();
      if (_bookingFor != 'Myself') {
        notes = '[Booking For: $_relationship] $notes'.trim();
      }

      final request = AppointmentRequest(
        doctorId: _doctorId!,
        branchId: _branchId!,
        startTime: _onSelectedDate(slot.startDateTime),
        endTime: _onSelectedDate(slot.endDateTime),
        patientName: _fullNameController.text.trim(),
        patientPhone: _mobileController.text.trim(),
        patientEmail: _emailController.text.trim(),
        reasonForVisit: _purpose,
        additionalNotes: notes,
      );

      await ref.read(appointmentRepositoryProvider).createAppointment(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment requested successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.goNamed(RouteNames.landing);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error booking appointment.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Leave booking?', style: AppTextStyles.titleMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave & sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.goNamed(RouteNames.landing);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('Book an Appointment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isSubmitting ? null : _confirmLeave,
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxWidth < AppDimensions.compactBreakpoint;
              return SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact
                      ? AppDimensions.paddingMedium
                      : AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingLarge,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autovalidateMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(isCompact),
                          const SizedBox(height: AppDimensions.paddingLarge),

                          // ── STEP 1: PATIENT INFORMATION ──────────────────────
                          FormSection(
                            step: 1,
                            title: 'Patient Information',
                            subtitle: 'Who is attending this appointment?',
                            children: [
                              // 🎴 CHOICE CARDS: Myself vs Guardian / Child
                              LabeledField(
                                label: 'Who is this appointment for?',
                                isRequired: true,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _ChoiceCard(
                                        title: 'Myself',
                                        subtitle: 'Book for yourself',
                                        icon: Icons.person_outline,
                                        selected: _bookingFor == 'Myself',
                                        onTap: () => _onBookingForChanged('Myself'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ChoiceCard(
                                        title: 'Child / Dependent',
                                        subtitle: 'Guardian books for minor',
                                        icon: Icons.family_restroom_outlined,
                                        selected: _bookingFor != 'Myself',
                                        onTap: () => _onBookingForChanged('Child / Dependent'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // If Guardian/Minor, show relationship selector
                              if (_bookingFor != 'Myself') ...[
                                LabeledField(
                                  label: 'Relationship to Patient',
                                  isRequired: true,
                                  child: DropdownButtonFormField<String>(
                                    value: _relationship,
                                    dropdownColor: AppColors.surface,
                                    style: _inputTextStyle,
                                    decoration: _inputDeco(
                                      'Select relationship',
                                      Icons.people_outline,
                                    ),
                                    items: _relationships
                                        .map((r) => DropdownMenuItem(
                                              value: r,
                                              child: Text(r),
                                            ))
                                        .toList(),
                                    onChanged: (val) =>
                                        setState(() => _relationship = val!),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Patient Name Field
                              LabeledField(
                                label: _bookingFor == 'Myself'
                                    ? 'Patient Full Name'
                                    : "Patient's (Child / Dependent) Full Name",
                                isRequired: true,
                                child: TextFormField(
                                  controller: _fullNameController,
                                  style: _inputTextStyle,
                                  readOnly: _bookingFor == 'Myself',
                                  decoration: _inputDeco(
                                    _bookingFor == 'Myself'
                                        ? 'Loaded from profile'
                                        : "Enter patient's full name",
                                    Icons.person_outline,
                                    readOnly: _bookingFor == 'Myself',
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? 'Enter the patient\'s full name'
                                      : null,
                                ),
                              ),

                              // Contact Fields (Guardian contact or Patient contact)
                              ResponsiveFieldRow(
                                isCompact: isCompact,
                                children: [
                                  LabeledField(
                                    label: _bookingFor == 'Myself'
                                        ? 'Mobile Number'
                                        : 'Guardian Mobile Number',
                                    isRequired: true,
                                    child: TextFormField(
                                      controller: _mobileController,
                                      style: _inputTextStyle,
                                      decoration: _inputDeco(
                                        '09XX XXX XXXX',
                                        Icons.phone_outlined,
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Enter mobile number'
                                              : null,
                                    ),
                                  ),
                                  LabeledField(
                                    label: _bookingFor == 'Myself'
                                        ? 'Email Address'
                                        : 'Guardian Email Address',
                                    isRequired: true,
                                    child: TextFormField(
                                      controller: _emailController,
                                      style: _inputTextStyle,
                                      decoration: _inputDeco(
                                        'you@email.com',
                                        Icons.mail_outline,
                                      ),
                                      validator: (v) =>
                                          v == null || !v.contains('@')
                                              ? 'Valid email required'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingLarge),

                          // ── STEP 2: APPOINTMENT DETAILS ──────────────────────
                          FormSection(
                            step: 2,
                            title: 'Appointment Details',
                            subtitle:
                                'Pick a schedule and tell us why you\'re coming in.',
                            children: [
                              ResponsiveFieldRow(
                                isCompact: isCompact,
                                children: [
                                  LabeledField(
                                      label: 'Branch',
                                      isRequired: true,
                                      child: _buildBranchField()),
                                  LabeledField(
                                      label: 'Dentist',
                                      isRequired: true,
                                      child: _buildDoctorField()),
                                ],
                              ),
                              LabeledField(
                                  label: 'Date',
                                  isRequired: true,
                                  child: _buildDateField()),
                              LabeledField(
                                  label: 'Time',
                                  isRequired: true,
                                  child: _buildTimeField()),
                              LabeledField(
                                label: 'Purpose of Visit',
                                isRequired: true,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _purpose,
                                  style: _inputTextStyle,
                                  dropdownColor: AppColors.surface,
                                  decoration: _inputDeco(
                                    'Select a service',
                                    Icons.medical_services_outlined,
                                  ),
                                  items: _purposes
                                      .map((e) => DropdownMenuItem(
                                          value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _purpose = value),
                                  validator: (v) =>
                                      v == null ? 'Select a purpose' : null,
                                ),
                              ),
                              LabeledField(
                                label: 'Additional Notes',
                                child: TextFormField(
                                  controller: _notesController,
                                  style: _inputTextStyle,
                                  maxLines: 4,
                                  decoration: _inputDeco(
                                    'Describe any symptoms or concerns...',
                                    Icons.edit_note,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingLarge),
                          _buildSubmitBar(isCompact),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAsyncField<T>({
    required AsyncValue<List<T>> async,
    required String hint,
    required IconData icon,
    required String errorLabel,
    required int? value,
    required List<DropdownMenuItem<int>> Function(List<T> items) itemBuilder,
    required ValueChanged<int?> onChanged,
    required String validationMessage,
  }) {
    return async.when(
      loading: () => const FieldPlaceholder(label: 'Loading...'),
      error: (error, _) => FieldPlaceholder(label: errorLabel, isError: true),
      data: (items) {
        if (items.isEmpty) {
          return FieldPlaceholder(label: errorLabel, isError: true);
        }
        return DropdownButtonFormField<int>(
          initialValue: value,
          style: _inputTextStyle,
          dropdownColor: AppColors.surface,
          decoration: _inputDeco(hint, icon),
          items: itemBuilder(items),
          onChanged: onChanged,
          validator: (v) => v == null ? validationMessage : null,
        );
      },
    );
  }

  Widget _buildDateField() {
    return FormField<DateTime>(
      initialValue: _selectedDate,
      validator: (_) => _selectedDate == null ? 'Select a date' : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookingCalendar(
              month: _visibleMonth,
              selectedDate: _selectedDate,
              dayLoad: _dayLoad,
              isLoading: _isLoadingDayLoad,
              firstSelectableDate: DateTime.now(),
              onMonthChanged: _onMonthChanged,
              onDateSelected: (date) {
                _onDateSelected(date);
                field.didChange(date);
              },
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Text(
                field.errorText!,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTimeField() {
    final availability = ref.watch(availabilityNotifierProvider);
    return FormField<TimeSlot>(
      initialValue: availability.selectedSlot,
      validator: (_) =>
          ref.read(availabilityNotifierProvider).selectedSlot == null
              ? 'Select a time'
              : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlotPickerGrid(
              state: availability,
              hasPrerequisites:
                  _doctorId != null && _branchId != null && _selectedDate != null,
              textStyle: _inputTextStyle,
              onSlotSelected: (slot) {
                ref
                    .read(availabilityNotifierProvider.notifier)
                    .selectSlot(slot);
                field.didChange(slot);
              },
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Text(
                field.errorText!,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBranchField() {
    return _buildAsyncField(
      async: ref.watch(branchesProvider),
      hint: 'Select a branch',
      icon: Icons.location_on_outlined,
      errorLabel: 'Error loading branches',
      value: _branchId,
      validationMessage: 'Select a branch',
      itemBuilder: (branches) => branches
          .map((b) => DropdownMenuItem<int>(value: b.id, child: Text(b.name)))
          .toList(),
      onChanged: (value) {
        setState(() => _branchId = value);
        _loadDayLoad();
        _reloadSlots();
      },
    );
  }

  Widget _buildDoctorField() {
    return _buildAsyncField(
      async: ref.watch(doctorsProvider),
      hint: 'Select a dentist',
      icon: Icons.medical_information_outlined,
      errorLabel: 'Error loading dentists',
      value: _doctorId,
      validationMessage: 'Select a dentist',
      itemBuilder: (doctors) => (doctors as List).map((d) {
        final map = d as Map<String, dynamic>;
        final id = map['id'] as int;
        final name = map['name']?.toString() ??
            (map['user'] as Map?)?['name']?.toString() ??
            'Doctor #$id';
        return DropdownMenuItem<int>(value: id, child: Text(name));
      }).toList(),
      onChanged: (value) {
        setState(() => _doctorId = value);
        _loadDayLoad();
        _reloadSlots();
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(
          isCompact ? AppDimensions.paddingLarge : AppDimensions.paddingXL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Book your visit',
              style: (isCompact
                      ? AppTextStyles.headlineSmall
                      : AppTextStyles.headlineMedium)
                  .copyWith(color: AppColors.textOnDark)),
          const SizedBox(height: 8),
          Text(
            'Two quick steps and your slot is reserved. We\'ll confirm by email and text.',
            style: AppTextStyles.bodyOnDark,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: const [
              HeaderNote(
                  icon: Icons.schedule_outlined,
                  label: 'About $_typicalDurationMinutes minutes'),
              HeaderNote(
                  icon: Icons.lock_outline,
                  label: 'Your details stay private'),
              HeaderNote(
                  icon: Icons.event_available_outlined,
                  label: 'Free to reschedule'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By booking, you agree to arrive 10 minutes early. No payment is required now.',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(_isSubmitting ? 'Booking...' : 'Book Appointment'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Choice Card Widget (Matches Consent Form Design) ─────────────────────────
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