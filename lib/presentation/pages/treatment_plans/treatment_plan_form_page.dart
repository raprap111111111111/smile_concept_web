// lib/presentation/pages/treatment_plans/treatment_plan_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/patient/patient_model.dart';
import '../../../data/models/treatment/treatment_plan_model.dart';
import '../../../data/repositories/treatment_plan_repository.dart';
import '../../providers/doctor/doctor_list_provider.dart';
import '../../providers/patient/patient_search_provider.dart';
import '../../providers/treatment/treatment_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/dashed_add_button.dart';
import 'widgets/dropdown_states.dart';
import 'widgets/empty_catalog_banner.dart';
import 'widgets/form_section_card.dart';
import 'widgets/grand_total_bar.dart';
import 'widgets/patient_picker_field.dart';
import 'widgets/plan_item_card.dart';

class TreatmentPlanFormPage extends ConsumerStatefulWidget {
  final int? patientId;
  final int? doctorId;

  const TreatmentPlanFormPage({super.key, this.patientId, this.doctorId});

  @override
  ConsumerState<TreatmentPlanFormPage> createState() =>
      _TreatmentPlanFormPageState();
}

class _TreatmentPlanFormPageState
    extends ConsumerState<TreatmentPlanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedDoctorId;
  PatientModel? _selectedPatient;
  bool _patientError = false;
  bool _isSubmitting = false;

  int? get _selectedPatientId => _selectedPatient?.userId;

  final List<TreatmentPlanItemForm> _items = [];

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.doctorId;
    _addItem();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(treatmentProvider.notifier).loadTreatments();

      if (widget.patientId != null) {
        _preloadPatient(widget.patientId!);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _preloadPatient(int userId) async {
    try {
      final patients = await ref.read(patientSearchProvider('').future);
      final match = patients.firstWhere(
        (p) => p.userId == userId,
        orElse: () => throw Exception('Patient not found in list'),
      );
      if (mounted) setState(() => _selectedPatient = match);
    } catch (_) {
      // Silently fail — admin can still pick manually
    }
  }

  void _addItem() => setState(() => _items.add(TreatmentPlanItemForm()));

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _moveItem(int index, int dir) {
    final target = index + dir;
    if (target < 0 || target >= _items.length) return;
    setState(() {
      final m = _items.removeAt(index);
      _items.insert(target, m);
    });
  }

  double get _grandTotal =>
      _items.fold(0.0, (sum, i) => sum + i.subtotal);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fill all required fields', isError: true);
      return;
    }

    if (_selectedPatient == null) {
      setState(() => _patientError = true);
      _showSnack('Please select a patient', isError: true);
      return;
    }
    if (_selectedDoctorId == null) {
      _showSnack('Please select a doctor', isError: true);
      return;
    }
    if (_items.isEmpty) {
      _showSnack('Add at least one treatment item', isError: true);
      return;
    }

    bool itemsValid = true;
    for (final i in _items) {
      if (i.selectedTreatment == null) {
        i.treatmentError = true;
        itemsValid = false;
      } else {
        i.treatmentError = false;
      }
    }
    if (!itemsValid) {
      setState(() {});
      _showSnack('Please select a treatment for every item', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final itemsPayload = [
        for (int idx = 0; idx < _items.length; idx++)
          _items[idx].toPayload(idx + 1),
      ];

      final notes = _notesController.text.trim();

      final repo = ref.read(treatmentPlanRepositoryProvider);
      await repo.create(
        userId: _selectedPatientId!,
        doctorId: _selectedDoctorId!,
        name: _nameController.text.trim(),
        items: itemsPayload,
        status: 'proposed',
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        _showSnack('Treatment plan created successfully', isError: false);
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    final bgColor = isError ? AppColors.error : AppColors.success;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treatmentState = ref.watch(treatmentProvider);
    final doctorsAsync = ref.watch(doctorSimpleListProvider);
    final catalogEmpty =
        !treatmentState.isListLoading && treatmentState.treatments.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              children: [
                // ═══════ Section 1: Plan Info ═══════
                FormSectionCard(
                  icon: Icons.assignment_outlined,
                  title: 'Plan Information',
                  subtitle: 'Basic details about this treatment plan',
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Plan Name *',
                        hint: "e.g. John's Dental Restoration",
                        icon: Icons.title_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notes (optional)',
                        hint: 'General notes about the plan...',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                        alignLabelWithHint: true,
                      ),
                    ],
                  ),
                ),

                // ═══════ Section 2: Participants ═══════
                FormSectionCard(
                  icon: Icons.groups_outlined,
                  title: 'Participants',
                  subtitle: 'Who is this treatment plan for?',
                  child: Column(
                    children: [
                      PatientPickerField(
                        selected: _selectedPatient,
                        hasError: _patientError,
                        onPicked: (p) => setState(() {
                          _selectedPatient = p;
                          _patientError = false;
                        }),
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      doctorsAsync.when(
                        loading: () =>
                            const DropdownLoading(label: 'Doctor *'),
                        error: (e, _) => DropdownError(
                          label: 'Doctor *',
                          error: e.toString(),
                          onRetry: () =>
                              ref.invalidate(doctorSimpleListProvider),
                        ),
                        data: (doctors) => _buildDoctorDropdown(doctors),
                      ),
                    ],
                  ),
                ),

                // ═══════ Section 3: Treatment Items ═══════
                FormSectionCard(
                  icon: Icons.medical_information_outlined,
                  title: 'Treatment Steps',
                  subtitle: 'Add the treatments included in this plan',
                  trailing: _buildStepCountBadge(),
                  child: Column(
                    children: [
                      if (catalogEmpty)
                        const EmptyCatalogBanner()
                      else ...[
                        ..._items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return PlanItemCard(
                            index: index,
                            item: item,
                            availableTreatments: treatmentState.treatments,
                            isLoading: treatmentState.isListLoading,
                            onMoveUp:
                                index > 0 ? () => _moveItem(index, -1) : null,
                            onMoveDown: index < _items.length - 1
                                ? () => _moveItem(index, 1)
                                : null,
                            onRemove: _items.length > 1
                                ? () => _removeItem(index)
                                : null,
                            onChanged: () => setState(() {}),
                          );
                        }),
                        const SizedBox(height: 6),
                        DashedAddButton(onTap: _addItem),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 100), // space for sticky bottom bar
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: GrandTotalBar(
        total: _grandTotal,
        itemCount: _items.length,
        isSubmitting: _isSubmitting,
        onSubmit: _submit,
      ),
    );
  }

  // ─── Sub-builders ──────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.ink),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'New Treatment Plan',
        style: AppTextStyles.titleLarge.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      shape: const Border(
        bottom: BorderSide(color: AppColors.line),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool alignLabelWithHint = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: AppColors.primaryDark, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            alignLabelWithHint: alignLabelWithHint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingMedium,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.6,
              ),
            ),
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorDropdown(List<dynamic> doctors) {
    final validSelected =
        doctors.any((d) => d.id == _selectedDoctorId)
            ? _selectedDoctorId
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doctor *',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: validSelected,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          dropdownColor: AppColors.background,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Select doctor',
            hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.medical_services_outlined,
              color: AppColors.primaryDark,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingMedium,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          items: doctors
              .map<DropdownMenuItem<int>>(
                (d) => DropdownMenuItem<int>(
                  value: d.id as int,
                  child: Text(
                    d.displayLabel as String,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedDoctorId = v),
          validator: (v) => v == null ? 'Please select a doctor' : null,
        ),
      ],
    );
  }

  Widget _buildStepCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentWithOpacity(0.22),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.accentWithOpacity(0.5)),
      ),
      child: Text(
        '${_items.length} step${_items.length == 1 ? '' : 's'}',
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}