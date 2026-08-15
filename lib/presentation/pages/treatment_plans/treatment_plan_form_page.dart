// lib/presentation/pages/treatment_plans/treatment_plan_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/doctor/doctor_simple_model.dart';
import '../../../data/models/patient/patient_model.dart';
import '../../../data/models/treatment/treatment_plan_model.dart';
import '../../../data/repositories/treatment_plan_repository.dart';
import '../../providers/doctor/doctor_list_provider.dart';
import '../../providers/patient/patient_search_provider.dart';
import '../../providers/treatment/treatment_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'widgets/dashed_add_button.dart';
import 'widgets/dropdown_states.dart';
import 'widgets/empty_catalog_banner.dart';
import 'widgets/form_section_card.dart';
import 'widgets/grand_total_bar.dart';
import 'widgets/patient_picker_field.dart';
import 'widgets/plan_item_card.dart';
import 'widgets/plan_summary_panel.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

/// Width at which the summary rail sits beside the form instead of collapsing
/// into the sticky bottom bar. Measured against the content area inside
/// MainLayout, not the window.
const double _railBreakpoint = 1040;

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

  final _scrollController = ScrollController();
  final _planSectionKey = GlobalKey();
  final _peopleSectionKey = GlobalKey();
  final _stepsSectionKey = GlobalKey();

  int? _selectedDoctorId;
  PatientModel? _selectedPatient;
  bool _patientError = false;
  bool _isSubmitting = false;

  /// Stays off until the first submit so the form does not scold a clinician
  /// who has only just landed on an empty page.
  bool _submitAttempted = false;

  int? get _selectedPatientId => _selectedPatient?.userId;

  final List<TreatmentPlanItemForm> _items = [];

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.doctorId;
    _addItem();

    // The summary rail mirrors the plan name live.
    _nameController.addListener(_onNameChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(treatmentProvider.notifier).loadTreatments();

      if (widget.patientId != null) {
        _preloadPatient(widget.patientId!);
      }
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

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

  double get _grandTotal => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  // ── Completion state ───────────────────────────────────────
  bool get _planInfoComplete => _nameController.text.trim().isNotEmpty;

  bool get _participantsComplete =>
      _selectedPatient != null && _selectedDoctorId != null;

  bool get _stepsComplete =>
      _items.isNotEmpty && _items.every((i) => i.selectedTreatment != null);

  List<PlanRequirement> get _requirements => [
        PlanRequirement('Plan name', met: _planInfoComplete),
        PlanRequirement('Patient', met: _selectedPatient != null),
        PlanRequirement('Doctor', met: _selectedDoctorId != null),
        PlanRequirement(
          'A treatment on every step',
          met: _stepsComplete,
        ),
      ];

  String? get _blockedReason {
    for (final r in _requirements) {
      if (!r.met) return 'Missing: ${r.label}';
    }
    return null;
  }

  /// True once anything worth losing has been entered.
  bool get _isDirty =>
      _nameController.text.trim().isNotEmpty ||
      _notesController.text.trim().isNotEmpty ||
      _selectedPatient != null ||
      _selectedDoctorId != null ||
      _items.any((i) =>
          i.selectedTreatment != null ||
          i.notesController.text.trim().isNotEmpty);

  // ── Submit ─────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _submitAttempted = true);

    final formValid = _formKey.currentState!.validate();

    // Flag every unmet requirement in one pass so the clinician sees all the
    // gaps at once rather than fixing them one snackbar at a time.
    setState(() {
      _patientError = _selectedPatient == null;
      for (final i in _items) {
        i.treatmentError = i.selectedTreatment == null;
      }
    });

    if (!formValid || _patientError || !_stepsComplete || _items.isEmpty) {
      _scrollToFirstProblem();
      _showSnack(
        _blockedReason ?? 'Please complete the highlighted fields',
        isError: true,
      );
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
        _showSnack(describeError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _scrollToFirstProblem() {
    final key = !_planInfoComplete
        ? _planSectionKey
        : !_participantsComplete
            ? _peopleSectionKey
            : _stepsSectionKey;

    final ctx = key.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _handleCancel() async {
    if (!_isDirty) {
      context.pop();
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) context.pop();
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.statusPendingSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.statusPendingInk,
          ),
        ),
        title: const Text(
          'Discard this plan?',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'The treatment steps and details you entered will be lost.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
        ),
      );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // main.dart still runs ThemeData.dark(); this page is designed light, so it
    // pins the intended light theme rather than inheriting dark surfaces —
    // otherwise the pickers and step cards land as dark blocks on white panels.
    return Theme(
      data: AppTheme.lightTheme,
      child: PopScope(
        canPop: !_isDirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final discard = await _confirmDiscard();
          if (discard && mounted) context.pop();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _railBreakpoint;
            return Scaffold(
              backgroundColor: AppColors.surface,
              body: Form(
                key: _formKey,
                autovalidateMode: _submitAttempted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: wide ? _wideLayout() : _narrowLayout(),
              ),
              bottomNavigationBar: wide
                  ? null
                  : GrandTotalBar(
                      total: _grandTotal,
                      itemCount: _items.length,
                      isSubmitting: _isSubmitting,
                      blockedReason: _blockedReason,
                      onSubmit: _submit,
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _wideLayout() {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: AppDimensions.paddingLarge),
                  children: _formSections(),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingLarge),
              SizedBox(
                width: 348,
                child: PlanSummaryPanel(
                  planName: _nameController.text,
                  patient: _selectedPatient,
                  doctorLabel: _selectedDoctorLabel,
                  items: _items,
                  requirements: _requirements,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submit,
                  onCancel: _handleCancel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _narrowLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          children: _formSections(),
        ),
      ),
    );
  }

  String? get _selectedDoctorLabel {
    if (_selectedDoctorId == null) return null;
    final doctors = ref.read(doctorSimpleListProvider).valueOrNull;
    if (doctors == null) return null;
    for (final d in doctors) {
      if (d.id == _selectedDoctorId) return d.displayLabel;
    }
    return null;
  }

  List<Widget> _formSections() {
    final treatmentState = ref.watch(treatmentProvider);
    final doctorsAsync = ref.watch(doctorSimpleListProvider);
    final catalogEmpty =
        !treatmentState.isListLoading && treatmentState.treatments.isEmpty;

    return [
      _PageHeader(
        completed: [
          _planInfoComplete,
          _participantsComplete,
          _stepsComplete,
        ].where((c) => c).length,
        onBack: _handleCancel,
      ),
      const SizedBox(height: AppDimensions.paddingLarge),

      // ═══════ Section 1: Plan Info ═══════
      FormSectionCard(
        key: _planSectionKey,
        step: 1,
        complete: _planInfoComplete,
        icon: Icons.assignment_outlined,
        title: 'Plan Information',
        subtitle: 'Name this plan so the front desk can find it later',
        child: Column(
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Plan Name *',
              hint: "e.g. John's Dental Restoration",
              icon: Icons.title_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Plan name is required' : null,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildTextField(
              controller: _notesController,
              label: 'Notes',
              optional: true,
              hint: 'Anything the treating doctor should know before starting…',
              icon: Icons.notes_outlined,
              maxLines: 3,
              alignLabelWithHint: true,
            ),
          ],
        ),
      ),

      // ═══════ Section 2: Participants ═══════
      FormSectionCard(
        key: _peopleSectionKey,
        step: 2,
        complete: _participantsComplete,
        icon: Icons.groups_outlined,
        title: 'Participants',
        subtitle: 'Who is this treatment plan for, and who will deliver it?',
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
              loading: () => const DropdownLoading(label: 'Doctor *'),
              error: (e, _) => DropdownError(
                label: 'Doctor *',
                error: describeError(e),
                onRetry: () => ref.invalidate(doctorSimpleListProvider),
              ),
              data: _buildDoctorDropdown,
            ),
          ],
        ),
      ),

      // ═══════ Section 3: Treatment Items ═══════
      FormSectionCard(
        key: _stepsSectionKey,
        step: 3,
        complete: _stepsComplete,
        icon: Icons.medical_information_outlined,
        title: 'Treatment Steps',
        subtitle: 'Sequence the treatments the patient will receive',
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
                  key: ObjectKey(item),
                  index: index,
                  item: item,
                  availableTreatments: treatmentState.treatments,
                  isLoading: treatmentState.isListLoading,
                  onMoveUp: index > 0 ? () => _moveItem(index, -1) : null,
                  onMoveDown: index < _items.length - 1
                      ? () => _moveItem(index, 1)
                      : null,
                  onRemove:
                      _items.length > 1 ? () => _removeItem(index) : null,
                  onChanged: () => setState(() {}),
                );
              }),
              const SizedBox(height: 6),
              DashedAddButton(onTap: _addItem),
            ],
          ],
        ),
      ),
    ];
  }

  // ─── Sub-builders ──────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool alignLabelWithHint = false,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.ink),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              const Text(
                'optional',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
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
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
            alignLabelWithHint: alignLabelWithHint,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      alignLabelWithHint: alignLabelWithHint,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingMedium,
      ),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.primary, 1.6),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.6),
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDoctorDropdown(List<DoctorSimpleModel> doctors) {
    final validSelected = doctors.any((d) => d.id == _selectedDoctorId)
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
          // Menu surface is pinned white so the item text (ink) keeps contrast
          // regardless of what the ambient theme resolves to.
          dropdownColor: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(
            hint: 'Select the treating doctor',
            icon: Icons.medical_services_outlined,
          ),
          items: doctors
              .map(
                (d) => DropdownMenuItem<int>(
                  value: d.id,
                  child: Text(
                    d.displayLabel,
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
    final done = _items.where((i) => i.selectedTreatment != null).length;
    final all = _items.length;
    final complete = done == all && all > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: complete
            ? AppColors.statusCompletedSoft
            : AppColors.accentWithOpacity(0.22),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: complete
              ? AppColors.statusCompletedInk.withValues(alpha: 0.3)
              : AppColors.accentWithOpacity(0.5),
        ),
      ),
      child: Text(
        '$done / $all step${all == 1 ? '' : 's'}',
        style: TextStyle(
          color: complete
              ? AppColors.statusCompletedInk
              : AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Page header
// ═══════════════════════════════════════════════════════════════
class _PageHeader extends StatelessWidget {
  /// How many of the three sections are filled in.
  final int completed;
  final VoidCallback onBack;

  const _PageHeader({required this.completed, required this.onBack});

  static const _total = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: 'Back to treatment plans',
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.ink,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    hoverColor: AppColors.accentWithOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius,
                      ),
                      side: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TREATMENT PLANS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'New Treatment Plan',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Build the plan in three short steps. '
                      'It is saved as Proposed — nothing is billed yet.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Row(
            children: [
              for (int i = 0; i < _total; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < completed
                          ? AppColors.primary
                          : AppColors.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < _total - 1) const SizedBox(width: 6),
              ],
              const SizedBox(width: 12),
              Text(
                '$completed of $_total done',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
