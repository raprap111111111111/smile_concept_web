// lib/presentation/pages/doctor_schedules/doctor_schedule_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/doctor_schedule/doctor_schedule_model.dart';
import '../../../data/repositories/doctor_schedule_repository.dart';
import '../../providers/doctor_schedule/doctor_schedule_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/branch_dropdown.dart';
import 'widgets/days_checkbox_list.dart';
import 'widgets/day_of_week_dropdown.dart';
import 'widgets/doctor_dropdown.dart';
import 'widgets/time_picker_field.dart';

class DoctorScheduleFormPage extends ConsumerStatefulWidget {
  final DoctorScheduleModel? existingSchedule;
  final int? prefillDoctorId;
  final int? prefillBranchId;

  const DoctorScheduleFormPage({
    super.key,
    this.existingSchedule,
    this.prefillDoctorId,
    this.prefillBranchId,
  });

  bool get isEditing => existingSchedule != null;

  @override
  ConsumerState<DoctorScheduleFormPage> createState() =>
      _DoctorScheduleFormPageState();
}

class _DoctorScheduleFormPageState
    extends ConsumerState<DoctorScheduleFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;

  int? _selectedDoctorId;
  int? _selectedBranchId;

  int? _selectedDay;
  Set<int> _selectedDays = {};

  bool _isSaving = false;
  String? _serverError;
  String? _serverWarning;

  DoctorScheduleRepository get _repository =>
      ref.read(doctorScheduleRepositoryProvider);

  @override
  void initState() {
    super.initState();
    final s = widget.existingSchedule;
    _selectedDoctorId = s?.doctorId ?? widget.prefillDoctorId;
    _selectedBranchId = s?.branchId ?? widget.prefillBranchId;
    _startTimeController = TextEditingController(text: s?.startTime ?? '');
    _endTimeController = TextEditingController(text: s?.endTime ?? '');
    _selectedDay = s?.dayOfWeek;
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctorId == null || _selectedBranchId == null) {
      setState(() => _serverError = 'Please select a doctor and a branch');
      return;
    }

    if (widget.isEditing) {
      if (_selectedDay == null) {
        setState(() => _serverError = 'Please select a day');
        return;
      }
    } else {
      if (_selectedDays.isEmpty) {
        setState(() => _serverError = 'Please select at least one day');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _serverError = null;
      _serverWarning = null;
    });

    try {
      if (widget.isEditing) {
        final result = await _repository.updateSchedule(
          id: widget.existingSchedule!.id,
          doctorId: _selectedDoctorId!,
          branchId: _selectedBranchId!,
          dayOfWeek: _selectedDay!,
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
        );
        if (mounted) Navigator.of(context).pop(result);
      } else {
        final results = await _repository.createBulkSchedules(
          doctorId: _selectedDoctorId!,
          branchId: _selectedBranchId!,
          daysOfWeek: _selectedDays.toList()..sort(),
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
        );

        if (mounted) {
          Navigator.of(context)
              .pop(results.isNotEmpty ? results.first : null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Successfully created ${results.length} schedule(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on PartialSuccessException catch (e) {
      setState(() {
        _serverWarning =
            'Created ${e.createdSchedules.length} schedule(s), but some failed:\n'
            '${e.errors.join('\n')}';
        _isSaving = false;
      });
    } on ValidationException catch (e) {
      setState(() {
        _serverError = e.errors.values.expand((v) => v as List).join('\n');
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _serverError = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? 'Edit Schedule' : 'New Schedule',
          style: AppTextStyles.titleLarge,
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Card ──────────────────────────
              _buildHeaderCard(),
              const SizedBox(height: AppDimensions.paddingMedium),

              // ── Info Banner (Create mode) ────────────
              if (!widget.isEditing) ...[
                _InfoBanner(),
                const SizedBox(height: AppDimensions.paddingMedium),
              ],

              // ── Warning ──────────────────────────────
              if (_serverWarning != null) ...[
                _WarningBanner(message: _serverWarning!),
                const SizedBox(height: AppDimensions.paddingMedium),
              ],

              // ── Error ────────────────────────────────
              if (_serverError != null) ...[
                _ErrorBanner(message: _serverError!),
                const SizedBox(height: AppDimensions.paddingMedium),
              ],

              // ── Form Card: Assignment ────────────────
              _FormCard(
                title: 'Assignment',
                icon: Icons.person_outline_rounded,
                children: [
                  DoctorDropdown(
                    value: _selectedDoctorId,
                    onChanged: (v) =>
                        setState(() => _selectedDoctorId = v),
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  BranchDropdown(
                    value: _selectedBranchId,
                    onChanged: (v) =>
                        setState(() => _selectedBranchId = v),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // ── Form Card: Schedule ──────────────────
              _FormCard(
                title: widget.isEditing ? 'Schedule Day' : 'Schedule Days',
                icon: Icons.calendar_today_rounded,
                children: [
                  if (widget.isEditing)
                    DayOfWeekDropdown(
                      value: _selectedDay,
                      onChanged: (v) => setState(() => _selectedDay = v),
                    )
                  else
                    DaysCheckboxList(
                      selectedDays: _selectedDays,
                      onChanged: (v) => setState(() => _selectedDays = v),
                    ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // ── Form Card: Time Range ────────────────
              _FormCard(
                title: 'Time Range',
                icon: Icons.access_time_rounded,
                children: [
                  TimePickerField(
                    controller: _startTimeController,
                    label: 'Start Time',
                    icon: Icons.play_arrow_rounded,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TimePickerField(
                    controller: _endTimeController,
                    label: 'End Time',
                    icon: Icons.stop_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (_startTimeController.text.isNotEmpty &&
                          v.trim().compareTo(
                                  _startTimeController.text.trim()) <=
                              0) {
                        return 'End time must be after start time';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // ── Actions ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadius),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    flex: 2,
                    child: _SubmitButton(
                      isSaving: _isSaving,
                      isEditing: widget.isEditing,
                      selectedCount: _selectedDays.length,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HEADER CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              widget.isEditing
                  ? Icons.edit_calendar_rounded
                  : Icons.event_available_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isEditing
                      ? 'Update Schedule'
                      : 'Create New Schedule',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isEditing
                      ? 'Modify doctor availability'
                      : 'Set doctor availability for one or more days',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORM CARD (Section wrapper)
// ═══════════════════════════════════════════════════════════════════════════════

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          ...children,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BANNERS
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.info,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk create',
                  style: TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select multiple days to create schedules in bulk. '
                  'Each day will use the same time range.',
                  style: TextStyle(
                    color: AppColors.info.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.error.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFB45309),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partial success',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUBMIT BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _SubmitButton extends StatelessWidget {
  final bool isSaving;
  final bool isEditing;
  final int selectedCount;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isSaving,
    required this.isEditing,
    required this.selectedCount,
    required this.onPressed,
  });

  String get _label {
    if (isEditing) return 'Save Changes';
    if (selectedCount == 0) return 'Create Schedule';
    if (selectedCount == 1) return 'Create 1 Schedule';
    return 'Create $selectedCount Schedules';
  }

  IconData get _icon {
    if (isEditing) return Icons.check_rounded;
    return Icons.add_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSaving ? null : AppColors.primaryGradient,
        color: isSaving ? AppColors.primary.withValues(alpha: 0.5) : null,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        boxShadow: isSaving
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          onTap: isSaving ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: isSaving
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}