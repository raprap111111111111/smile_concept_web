// lib/presentation/pages/treatment_plans/widgets/plan_summary_panel.dart

import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../../data/models/patient/patient_model.dart';
import '../../../../data/models/treatment/treatment_plan_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

/// A single unmet requirement blocking submission.
class PlanRequirement {
  final String label;
  final bool met;

  const PlanRequirement(this.label, {required this.met});
}

/// Sticky right rail on wide screens: live recap of the plan being built plus
/// a readiness checklist, so the clinician can see what is still missing
/// without scrolling back through the form.
class PlanSummaryPanel extends StatelessWidget {
  final String planName;
  final PatientModel? patient;
  final String? doctorLabel;
  final List<TreatmentPlanItemForm> items;
  final List<PlanRequirement> requirements;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const PlanSummaryPanel({
    super.key,
    required this.planName,
    required this.patient,
    required this.doctorLabel,
    required this.items,
    required this.requirements,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onCancel,
  });

  double get _total => items.fold(0.0, (sum, i) => sum + i.subtotal);

  int get _selectedCount =>
      items.where((i) => i.selectedTreatment != null).length;

  bool get _ready => requirements.every((r) => r.met);

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _metaRow(
                    Icons.badge_outlined,
                    'Plan',
                    planName.trim().isEmpty ? 'Untitled plan' : planName.trim(),
                    muted: planName.trim().isEmpty,
                  ),
                  const SizedBox(height: 12),
                  _metaRow(
                    Icons.person_outline_rounded,
                    'Patient',
                    patient?.name ?? 'Not selected',
                    muted: patient == null,
                  ),
                  const SizedBox(height: 12),
                  _metaRow(
                    Icons.medical_services_outlined,
                    'Doctor',
                    doctorLabel ?? 'Not selected',
                    muted: doctorLabel == null,
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: AppColors.line),
                  const SizedBox(height: 14),
                  _stepsHeading(),
                  const SizedBox(height: 10),
                  ..._stepRows(),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.line),
                  const SizedBox(height: 14),
                  _checklist(),
                ],
              ),
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────
  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusLarge - 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentWithOpacity(0.25),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Plan Summary',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(
    IconData icon,
    String label,
    String value, {
    bool muted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
                  fontStyle: muted ? FontStyle.italic : FontStyle.normal,
                  color: muted ? AppColors.textTertiary : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepsHeading() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'TREATMENT STEPS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          '$_selectedCount of ${items.length} set',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  List<Widget> _stepRows() {
    if (items.isEmpty) {
      return const [
        Text(
          'No steps added yet.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppColors.textTertiary,
          ),
        ),
      ];
    }

    return [
      for (int i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  '${i + 1}.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  items[i].selectedTreatment?.name ?? 'Not selected',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: items[i].selectedTreatment == null
                        ? AppColors.textTertiary
                        : AppColors.ink,
                    fontStyle: items[i].selectedTreatment == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                items[i].selectedTreatment == null
                    ? '—'
                    : formatMoney(items[i].subtotal),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _checklist() {
    final pending = requirements.where((r) => !r.met).toList();

    if (pending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.statusCompletedSoft,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(
            color: AppColors.statusCompletedInk.withValues(alpha: 0.25),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: AppColors.statusCompletedInk,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ready to create',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusCompletedInk,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusPendingSoft,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: AppColors.statusPendingInk.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pending_actions_rounded,
                size: 16,
                color: AppColors.statusPendingInk,
              ),
              const SizedBox(width: 8),
              Text(
                'Still needed (${pending.length})',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.statusPendingInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final r in pending)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 3),
              child: Text(
                '• ${r.label}',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusPendingInk,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.borderRadiusLarge - 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  'Grand total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                formatMoney(_total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(
                      _ready
                          ? Icons.check_circle_outline_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
              label: Text(isSubmitting ? 'Saving…' : 'Create Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: isSubmitting ? null : onCancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
