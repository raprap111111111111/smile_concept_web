// lib/presentation/pages/doctor_schedules/doctor_schedule_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ Fixed import path — model is in doctor_schedule/ folder, not auth/
import '../../../data/models/doctor_schedule/doctor_schedule_model.dart';

import '../../../data/repositories/doctor_schedule_repository.dart';
import '../../providers/doctor_schedule/doctor_schedule_provider.dart';
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

  // Edit mode → single day
  int? _selectedDay;

  // Create mode → multiple days
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
        // ── EDIT: single schedule ──────────────────────────────────
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
        // ── CREATE: bulk schedules ─────────────────────────────────
        final results = await _repository.createBulkSchedules(
          doctorId: _selectedDoctorId!,
          branchId: _selectedBranchId!,
          daysOfWeek: _selectedDays.toList()..sort(),
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
        );

        if (mounted) {
          Navigator.of(context).pop(results.isNotEmpty ? results.first : null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully created ${results.length} schedule(s).',
              ),
              backgroundColor: Colors.green.shade700,
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
        _serverError =
            e.errors.values.expand((v) => v as List).join('\n');
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
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Schedule' : 'New Schedule'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Info Banner (Create mode) ────────────────────────────
              if (!widget.isEditing) ...[
                _InfoBanner(),
                const SizedBox(height: 16),
              ],

              // ── Warning (partial success) ────────────────────────────
              if (_serverWarning != null) ...[
                _WarningBanner(message: _serverWarning!),
                const SizedBox(height: 16),
              ],

              // ── Error ────────────────────────────────────────────────
              if (_serverError != null) ...[
                _ErrorBanner(message: _serverError!),
                const SizedBox(height: 16),
              ],

              // ── Doctor ───────────────────────────────────────────────
              DoctorDropdown(
                value: _selectedDoctorId,
                onChanged: (v) => setState(() => _selectedDoctorId = v),
              ),
              const SizedBox(height: 16),

              // ── Branch ───────────────────────────────────────────────
              BranchDropdown(
                value: _selectedBranchId,
                onChanged: (v) => setState(() => _selectedBranchId = v),
              ),
              const SizedBox(height: 16),

              // ── Day(s) — dropdown for edit, checkboxes for create ───
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
              const SizedBox(height: 16),

              // ── Start Time ───────────────────────────────────────────
              TimePickerField(
                controller: _startTimeController,
                label: 'Start Time',
                icon: Icons.access_time,
              ),
              const SizedBox(height: 16),

              // ── End Time ─────────────────────────────────────────────
              TimePickerField(
                controller: _endTimeController,
                label: 'End Time',
                icon: Icons.access_time_filled_outlined,
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
              const SizedBox(height: 28),

              // ── Submit ───────────────────────────────────────────────
              _SubmitButton(
                isSaving: _isSaving,
                isEditing: widget.isEditing,
                selectedCount: _selectedDays.length,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Private helper widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Select multiple days to create schedules in bulk. '
              'Each day will use the same time range below.',
              style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined,
              color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: Colors.orange.shade900)),
          ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isSaving ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(_label, style: const TextStyle(fontSize: 16)),
    );
  }
}