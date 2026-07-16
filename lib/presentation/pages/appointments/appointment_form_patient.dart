import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smile_concept_web/data/models/appointment/appointment_request.dart';

import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/doctor_repository.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/branch/branch_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

class AppointmentFormPatient extends ConsumerStatefulWidget {
  const AppointmentFormPatient({super.key});

  @override
  ConsumerState<AppointmentFormPatient> createState() =>
      _AppointmentFormPatientState();
}

class _AppointmentFormPatientState
    extends ConsumerState<AppointmentFormPatient> {
  static const int _appointmentDurationMinutes = 30;
  static const double _formMaxWidth = 720;

  /// Typed/selected values read darker than the muted default body text.
  static final TextStyle _inputTextStyle = AppTextStyles.bodyMedium.copyWith(
    color: AppColors.ink,
    fontWeight: FontWeight.w500,
  );

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String? _purpose;
  String? _bookingFor;
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

  final List<String> _bookingOptions = [
    'Myself',
    'Spouse',
    'Child',
    'Parent',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _bookingFor = _bookingOptions.first;
    _applyAccountDetails();
  }

  /// The account holder is the default patient, so prefill from their profile
  /// rather than making them retype what we already know.
  void _applyAccountDetails() {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    _fullNameController.text = user.name;
    _emailController.text = user.email;
    _mobileController.text = user.phone ?? '';
  }

  void _onBookingForChanged(String? value) {
    setState(() {
      _bookingFor = value;

      if (value == _bookingOptions.first) {
        _applyAccountDetails();
        return;
      }

      // Booking for someone else — their details are not the account holder's.
      _fullNameController.clear();
      _mobileController.clear();
      _emailController.clear();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'Select appointment date',
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = DateFormat('MMMM d, yyyy').format(date);
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Select appointment time',
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
        _timeController.text = _formatTimeOfDay(time);
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();

    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    return DateFormat('h:mm a').format(dt);
  }

  DateTime _combineDateAndTime() {
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please complete the highlighted fields.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    // While the pickers are still loading or failed to load, no dropdown exists
    // for the form to validate — so check them directly rather than trusting
    // validate() to have covered them.
    if (_doctorId == null || _branchId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please choose a branch and dentist first.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    setState(() => _isSubmitting = true);

    final startTime = _combineDateAndTime();

    final endTime = startTime.add(
      const Duration(minutes: _appointmentDurationMinutes),
    );

    // The appointment belongs to the signed-in account; patient_* describes who
    // actually attends, which differs when booking for a family member.
    final request = AppointmentRequest(
      doctorId: _doctorId!,
      branchId: _branchId!,
      startTime: startTime,
      endTime: endTime,

      patientName: _fullNameController.text.trim(),
      patientPhone: _mobileController.text.trim(),
      patientEmail: _emailController.text.trim(),

      reasonForVisit: _purpose,
      additionalNotes: _notesController.text.trim(),
    );

    try {
      await ref.read(appointmentRepositoryProvider).createAppointment(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Appointment requested for '
              '${DateFormat('MMMM d').format(startTime)} at '
              '${_timeController.text}. We\'ll confirm by email.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

      context.goNamed(RouteNames.landing);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_readableError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  /// Surfaces the API's reason instead of a raw exception dump. The common case
  /// is a 422 for a slot that was taken between loading the form and submitting.
  String _readableError(Object e) {
    final message = e
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('ApiFailure: ', '');

    if (message.toLowerCase().contains('already booked')) {
      return 'That time slot was just taken. Please pick another time.';
    }

    return 'Could not book the appointment. $message';
  }

  @override
  Widget build(BuildContext context) {
    // main.dart still runs ThemeData.dark(); this page is designed light, so it
    // pins the intended light theme rather than inheriting dark input styles.
    return Theme(
      data: AppTheme.lightTheme,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Book an Appointment'),
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

                        _FormSection(
                          step: 1,
                          title: 'Patient Information',
                          subtitle: 'We use this to confirm your booking.',
                          children: [
                            _LabeledField(
                              label: 'Full Name',
                              isRequired: true,
                              child: TextFormField(
                                controller: _fullNameController,
                                style: _inputTextStyle,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Juan Dela Cruz',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Enter the patient\'s full name'
                                        : null,
                              ),
                            ),

                            _ResponsiveFieldRow(
                              isCompact: isCompact,
                              children: [
                                _LabeledField(
                                  label: 'Mobile Number',
                                  isRequired: true,
                                  child: TextFormField(
                                    controller: _mobileController,
                                    style: _inputTextStyle,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      hintText: '09XX XXX XXXX',
                                      prefixIcon: Icon(Icons.phone_outlined),
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Enter a mobile number'
                                            : null,
                                  ),
                                ),
                                _LabeledField(
                                  label: 'Email',
                                  isRequired: true,
                                  child: TextFormField(
                                    controller: _emailController,
                                    style: _inputTextStyle,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      hintText: 'you@email.com',
                                      prefixIcon: Icon(Icons.mail_outline),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Enter an email address';
                                      }

                                      if (!RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+',
                                      ).hasMatch(v.trim())) {
                                        return 'Enter a valid email address';
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            _LabeledField(
                              label: 'Booking For',
                              isRequired: true,
                              helperText:
                                  'Who is this appointment for?',
                              child: DropdownButtonFormField<String>(
                                initialValue: _bookingFor,
                                style: _inputTextStyle,
                                dropdownColor: AppColors.background,
                                iconEnabledColor: AppColors.textSecondary,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.borderRadius,
                                ),
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  hintText: 'Select an option',
                                  prefixIcon: Icon(Icons.people_outline),
                                ),
                                items: _bookingOptions
                                    .map(
                                      (option) => DropdownMenuItem<String>(
                                        value: option,
                                        child: Text(option),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _onBookingForChanged,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Select who the appointment is for'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimensions.paddingLarge),

                        _FormSection(
                          step: 2,
                          title: 'Appointment Details',
                          subtitle:
                              'Pick a schedule and tell us why you\'re coming in.',
                          children: [
                            _ResponsiveFieldRow(
                              isCompact: isCompact,
                              children: [
                                _LabeledField(
                                  label: 'Branch',
                                  isRequired: true,
                                  child: _buildBranchField(),
                                ),
                                _LabeledField(
                                  label: 'Dentist',
                                  isRequired: true,
                                  child: _buildDoctorField(),
                                ),
                              ],
                            ),

                            _ResponsiveFieldRow(
                              isCompact: isCompact,
                              children: [
                                _LabeledField(
                                  label: 'Date',
                                  isRequired: true,
                                  child: TextFormField(
                                    controller: _dateController,
                                    style: _inputTextStyle,
                                    readOnly: true,
                                    onTap: _pickDate,
                                    mouseCursor: SystemMouseCursors.click,
                                    decoration: const InputDecoration(
                                      hintText: 'Choose a date',
                                      prefixIcon:
                                          Icon(Icons.calendar_today_outlined),
                                      suffixIcon: Icon(
                                        Icons.expand_more,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Select a date'
                                        : null,
                                  ),
                                ),
                                _LabeledField(
                                  label: 'Time',
                                  isRequired: true,
                                  child: TextFormField(
                                    controller: _timeController,
                                    style: _inputTextStyle,
                                    readOnly: true,
                                    onTap: _pickTime,
                                    mouseCursor: SystemMouseCursors.click,
                                    decoration: const InputDecoration(
                                      hintText: 'Choose a time',
                                      prefixIcon: Icon(Icons.schedule_outlined),
                                      suffixIcon: Icon(
                                        Icons.expand_more,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Select a time'
                                        : null,
                                  ),
                                ),
                              ],
                            ),

                            if (_selectedDate != null && _selectedTime != null)
                              _ScheduleSummary(
                                date: _selectedDate!,
                                time: _timeController.text,
                                durationMinutes: _appointmentDurationMinutes,
                              ),

                            _LabeledField(
                              label: 'Purpose of Visit',
                              isRequired: true,
                              child: DropdownButtonFormField<String>(
                                initialValue: _purpose,
                                style: _inputTextStyle,
                                dropdownColor: AppColors.background,
                                iconEnabledColor: AppColors.textSecondary,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.borderRadius,
                                ),
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  hintText: 'Select a service',
                                  prefixIcon:
                                      Icon(Icons.medical_services_outlined),
                                ),
                                items: _purposes
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _purpose = value);
                                },
                                validator: (v) =>
                                    v == null ? 'Select a purpose' : null,
                              ),
                            ),

                            _LabeledField(
                              label: 'Additional Notes',
                              helperText:
                                  'Optional. Symptoms, allergies, or anything we should know.',
                              child: TextFormField(
                                controller: _notesController,
                                style: _inputTextStyle,
                                maxLines: 4,
                                maxLength: 500,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Describe any symptoms or concerns...',
                                  alignLabelWithHint: true,
                                  counterStyle: AppTextStyles.labelSmall,
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
    );
  }

  /// Shared chrome for the async-backed pickers, so a loading or failed fetch
  /// still occupies the field's slot instead of collapsing the layout.
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
      loading: () => const _FieldPlaceholder(label: 'Loading...'),
      error: (error, _) => _FieldPlaceholder(
        label: errorLabel,
        isError: true,
      ),
      data: (items) {
        if (items.isEmpty) {
          return _FieldPlaceholder(label: errorLabel, isError: true);
        }

        return DropdownButtonFormField<int>(
          initialValue: value,
          style: _inputTextStyle,
          dropdownColor: AppColors.background,
          iconEnabledColor: AppColors.textSecondary,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
          items: itemBuilder(items),
          onChanged: onChanged,
          validator: (v) => v == null ? validationMessage : null,
        );
      },
    );
  }

  Widget _buildBranchField() {
    return _buildAsyncField(
      async: ref.watch(branchesProvider),
      hint: 'Select a branch',
      icon: Icons.location_on_outlined,
      errorLabel: 'Could not load branches',
      value: _branchId,
      validationMessage: 'Select a branch',
      itemBuilder: (branches) => branches
          .map(
            (branch) => DropdownMenuItem<int>(
              value: branch.id,
              child: Text(branch.name),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _branchId = value),
    );
  }

  Widget _buildDoctorField() {
    return _buildAsyncField(
      async: ref.watch(doctorsProvider),
      hint: 'Select a dentist',
      icon: Icons.medical_information_outlined,
      errorLabel: 'Could not load dentists',
      value: _doctorId,
      validationMessage: 'Select a dentist',
      itemBuilder: (doctors) => doctors.map((doctor) {
        final id = doctor['id'] as int;

        final name = doctor['name']?.toString() ??
            (doctor['user'] as Map?)?['name']?.toString() ??
            'Doctor #$id';

        return DropdownMenuItem<int>(
          value: id,
          child: Text(name),
        );
      }).toList(),
      onChanged: (value) => setState(() => _doctorId = value),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(
        isCompact ? AppDimensions.paddingLarge : AppDimensions.paddingXL,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book your visit',
            style: (isCompact
                    ? AppTextStyles.headlineSmall
                    : AppTextStyles.headlineMedium)
                .copyWith(color: AppColors.textOnDark),
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            'Two quick steps and your slot is reserved. '
            'We\'ll confirm by email and text.',
            style: AppTextStyles.bodyOnDark,
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          Wrap(
            spacing: AppDimensions.paddingLarge,
            runSpacing: AppDimensions.paddingSmall,
            children: const [
              _HeaderNote(
                icon: Icons.schedule_outlined,
                label: '$_appointmentDurationMinutes-minute visit',
              ),
              _HeaderNote(
                icon: Icons.lock_outline,
                label: 'Your details stay private',
              ),
              _HeaderNote(
                icon: Icons.event_available_outlined,
                label: 'Free to reschedule',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By booking, you agree to arrive 10 minutes early. '
            'No payment is required now.',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: AppColors.primaryLight,
                disabledForegroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                textStyle: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                _isSubmitting ? 'Booking...' : 'Book Appointment',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stands in for a dropdown while its options load, or when the fetch fails.
/// Matches input height so the form doesn't jump once data arrives.
class _FieldPlaceholder extends StatelessWidget {
  final String label;
  final bool isError;

  const _FieldPlaceholder({required this.label, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: isError ? AppColors.error : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          if (isError)
            const Icon(
              Icons.error_outline,
              size: AppDimensions.iconSizeSmall,
              color: AppColors.error,
            )
          else
            const SizedBox(
              width: AppDimensions.iconSizeSmall,
              height: AppDimensions.iconSizeSmall,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isError ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trust note shown on the gradient header.
class _HeaderNote extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderNote({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppDimensions.iconSizeSmall,
          color: AppColors.textOnDarkMuted,
        ),
        const SizedBox(width: AppDimensions.paddingXS),
        Text(label, style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textOnDarkMuted,
        )),
      ],
    );
  }
}

/// Numbered card that groups related fields.
class _FormSection extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _FormSection({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accentLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.labelMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          const Divider(),
          const SizedBox(height: AppDimensions.paddingMedium),
          ...children,
        ],
      ),
    );
  }
}

/// Field with a persistent label above the input, so the label stays
/// readable while typing (floating labels shrink out of view).
class _LabeledField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? helperText;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
    this.isRequired = false,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.labelLarge),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          if (helperText != null) ...[
            const SizedBox(height: 2),
            Text(helperText!, style: AppTextStyles.labelSmall),
          ],
          const SizedBox(height: AppDimensions.paddingXS),
          child,
        ],
      ),
    );
  }
}

/// Side-by-side on wide screens, stacked on narrow ones.
class _ResponsiveFieldRow extends StatelessWidget {
  final bool isCompact;
  final List<Widget> children;

  const _ResponsiveFieldRow({
    required this.isCompact,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// Recap of the chosen slot, shown once date and time are both set.
class _ScheduleSummary extends StatelessWidget {
  final DateTime date;
  final String time;
  final int durationMinutes;

  const _ScheduleSummary({
    required this.date,
    required this.time,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: AppDimensions.iconSizeMedium,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: AppDimensions.paddingXS),
          Expanded(
            child: Text(
              '${DateFormat('EEEE, MMMM d').format(date)} at $time '
              '· $durationMinutes minutes',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
