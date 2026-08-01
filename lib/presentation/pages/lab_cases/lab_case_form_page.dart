// lib/presentation/pages/lab_cases/lab_case_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/theme/app_dimensions.dart';
import 'package:smile_concept_web/presentation/theme/app_text_styles.dart';
import 'package:smile_concept_web/data/models/lab_case/lab_case_constants.dart';
import 'package:smile_concept_web/data/models/lab_case/lab_case_model.dart';
import 'package:smile_concept_web/data/repositories/lab_case_repository.dart';
import 'package:smile_concept_web/presentation/providers/lab_case/lab_case_provider.dart';

class LabCaseFormPage extends ConsumerStatefulWidget {
  final int? id;

  const LabCaseFormPage({super.key, this.id});

  @override
  ConsumerState<LabCaseFormPage> createState() => _LabCaseFormPageState();
}

class _LabCaseFormPageState extends ConsumerState<LabCaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _displayDateFormat = DateFormat('MMM d, yyyy');

  final _labNameController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  int? _appointmentId;
  String? _appointmentDisplay;
  String _workType = LabWorkType.crown;
  String _status = LabCaseStatus.sent;
  DateTime _sentDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  DateTime? _receivedDate;
  bool _isLoadingCase = false;

  bool get _isEditMode => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) _loadExistingCase();
  }

  @override
  void dispose() {
    _labNameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCase() async {
    setState(() => _isLoadingCase = true);
    try {
      final repo = ref.read(labCaseRepositoryProvider);
      final labCase = await repo.getOne(widget.id!);
      _populateForm(labCase);
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to load lab case: $e', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _isLoadingCase = false);
    }
  }

  void _populateForm(LabCaseModel lc) {
    _labNameController.text = lc.labName;
    _costController.text = lc.cost?.toString() ?? '';
    _notesController.text = lc.notes ?? '';
    setState(() {
      _appointmentId = lc.appointmentId;
      _appointmentDisplay =
          lc.patientName ?? 'Appointment #${lc.appointmentId}';
      _workType = lc.workType;
      _status = lc.status;
      _sentDate = lc.sentDate;
      _dueDate = lc.dueDate;
      _receivedDate = lc.receivedDate;
    });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_appointmentId == null) {
      _showSnack('Please select an appointment.', AppColors.error);
      return;
    }

    final body = <String, dynamic>{
      'appointment_id': _appointmentId,
      'lab_name': _labNameController.text.trim(),
      'work_type': _workType,
      'status': _status,
      'sent_date': _dateFormat.format(_sentDate),
      'due_date': _dateFormat.format(_dueDate),
      if (_receivedDate != null)
        'received_date': _dateFormat.format(_receivedDate!),
      if (_costController.text.isNotEmpty)
        'cost': double.tryParse(_costController.text.trim()),
      if (_notesController.text.isNotEmpty)
        'notes': _notesController.text.trim(),
    };

    final notifier = ref.read(labCaseProvider.notifier);
    final success = _isEditMode
        ? await notifier.updateLabCase(widget.id!, body)
        : await notifier.createLabCase(body);

    if (success && mounted) {
      _showSnack(
        _isEditMode
            ? 'Lab case updated successfully.'
            : 'Lab case created successfully.',
        AppColors.success,
      );
      context.pop();
    }
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _openAppointmentPicker() async {
    final result = await showDialog<_AppointmentPickResult>(
      context: context,
      builder: (_) => const _AppointmentPickerDialog(),
    );
    if (result != null) {
      setState(() {
        _appointmentId = result.id;
        _appointmentDisplay = result.display;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(labCaseProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusSmall),
              ),
              child: Icon(Icons.science_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              _isEditMode ? 'Edit Lab Case' : 'New Lab Case',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoadingCase
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Case Info ──
                        _buildSection(
                          title: 'Case Information',
                          icon: Icons.science_outlined,
                          children: [
                            _AppointmentField(
                              displayText: _appointmentDisplay,
                              hasError: false,
                              onTap: _openAppointmentPicker,
                              onClear: _appointmentId != null
                                  ? () => setState(() {
                                        _appointmentId = null;
                                        _appointmentDisplay = null;
                                      })
                                  : null,
                            ),
                            const SizedBox(
                                height: AppDimensions.paddingMedium),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _labNameController,
                                    label: 'Lab Name',
                                    hint: 'e.g. Dental Excellence Lab',
                                    prefixIcon: Icons.business_outlined,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Lab name is required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(
                                    width: AppDimensions.paddingMedium),
                                Expanded(
                                  child: _buildDropdown<String>(
                                    label: 'Work Type',
                                    value: _workType,
                                    items: LabWorkType.all,
                                    itemLabel: (v) => v,
                                    icon: Icons.build_outlined,
                                    onChanged: (v) =>
                                        setState(() => _workType = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: AppDimensions.paddingMedium),
                            _buildDropdown<String>(
                              label: 'Status',
                              value: _status,
                              items: LabCaseStatus.all,
                              itemLabel: LabCaseStatus.label,
                              icon: Icons.flag_outlined,
                              onChanged: (v) =>
                                  setState(() => _status = v!),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimensions.paddingLarge),

                        // ── Dates ──
                        _buildSection(
                          title: 'Dates',
                          icon: Icons.calendar_today_outlined,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Sent Date',
                                    value: _sentDate,
                                    onTap: () => _pickDate(
                                      initial: _sentDate,
                                      onPicked: (d) =>
                                          setState(() => _sentDate = d),
                                    ),
                                    required: true,
                                  ),
                                ),
                                const SizedBox(
                                    width: AppDimensions.paddingMedium),
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Due Date',
                                    value: _dueDate,
                                    onTap: () => _pickDate(
                                      initial: _dueDate,
                                      firstDate: _sentDate,
                                      onPicked: (d) =>
                                          setState(() => _dueDate = d),
                                    ),
                                    required: true,
                                  ),
                                ),
                                const SizedBox(
                                    width: AppDimensions.paddingMedium),
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Received Date',
                                    value: _receivedDate,
                                    onTap: () => _pickDate(
                                      initial: _receivedDate ?? _dueDate,
                                      onPicked: (d) => setState(
                                          () => _receivedDate = d),
                                    ),
                                    required: false,
                                    onClear: () => setState(
                                        () => _receivedDate = null),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimensions.paddingLarge),

                        // ── Cost & Notes ──
                        _buildSection(
                          title: 'Cost & Notes',
                          icon: Icons.receipt_long_outlined,
                          children: [
                            _buildTextField(
                              controller: _costController,
                              label: 'Cost (optional)',
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              prefixIcon: Icons.attach_money_outlined,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                if (double.tryParse(v) == null) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(
                                height: AppDimensions.paddingMedium),
                            _buildTextField(
                              controller: _notesController,
                              label: 'Notes (optional)',
                              hint: 'Any special instructions or remarks…',
                              maxLines: 4,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimensions.paddingXL),

                        // ── Actions ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                side: BorderSide(color: AppColors.border),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(
                                width: AppDimensions.paddingMedium),
                            FilledButton.icon(
                              onPressed:
                                  state.isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 14),
                              ),
                              icon: state.isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _isEditMode
                                          ? Icons.save_outlined
                                          : Icons.add,
                                      size: 18),
                              label: Text(_isEditMode
                                  ? 'Save Changes'
                                  : 'Create Lab Case'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ─── Section wrapper ───

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusSmall),
                ),
                child:
                    Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.paddingMedium),
          ...children,
        ],
      ),
    );
  }

  // ─── Field helpers ───

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: AppColors.textSecondary)
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required bool required,
    VoidCallback? onClear,
  }) {
    return FormField<DateTime>(
      validator: (_) {
        if (required && value == null) return '$label is required';
        return null;
      },
      builder: (field) => InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusSmall),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: field.errorText,
            prefixIcon: Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.textSecondary),
            suffixIcon: (value != null && !required)
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusSmall),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusSmall),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
          child: Text(
            value != null ? _displayDateFormat.format(value) : 'Select date',
            style: value != null
                ? AppTextStyles.bodyMedium
                : AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ─── Appointment field (with clear + tap to open picker) ────────────────

class _AppointmentField extends StatelessWidget {
  final String? displayText;
  final bool hasError;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _AppointmentField({
    required this.displayText,
    required this.hasError,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Appointment *',
          prefixIcon: Icon(Icons.event_note_outlined,
              size: 18, color: AppColors.textSecondary),
          suffixIcon: displayText != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: onClear,
                )
              : Icon(Icons.search, size: 18, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusSmall),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusSmall),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
        child: Text(
          displayText ?? 'Tap to search appointments…',
          style: displayText != null
              ? AppTextStyles.bodyMedium
              : AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  APPOINTMENT PICKER DIALOG
//  Simple manual-entry version. Replace with real search from your
//  appointmentProvider when you're ready.
// ═══════════════════════════════════════════════════════════════════════

class _AppointmentPickResult {
  final int id;
  final String display;
  const _AppointmentPickResult(this.id, this.display);
}

class _AppointmentPickerDialog extends StatefulWidget {
  const _AppointmentPickerDialog();

  @override
  State<_AppointmentPickerDialog> createState() =>
      _AppointmentPickerDialogState();
}

class _AppointmentPickerDialogState
    extends State<_AppointmentPickerDialog> {
  final _idController = TextEditingController();
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _confirm() {
    final id = int.tryParse(_idController.text.trim());
    if (id == null) return;
    final label = _labelController.text.trim();
    Navigator.pop(
      context,
      _AppointmentPickResult(
        id,
        label.isEmpty ? 'Appointment #$id' : label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusSmall),
                    ),
                    child: Icon(Icons.event_note_outlined,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Select Appointment',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              Text(
                'Enter the appointment ID (and an optional label like the patient name).',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              TextField(
                controller: _idController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  labelText: 'Appointment ID',
                  hintText: 'e.g. 1',
                  prefixIcon: const Icon(Icons.tag, size: 18),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusSmall),
                  ),
                ),
                autofocus: true,
                onSubmitted: (_) => _confirm(),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              TextField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: 'Display label (optional)',
                  hintText: 'e.g. Ryan Ryan',
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusSmall),
                  ),
                ),
                onSubmitted: (_) => _confirm(),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}