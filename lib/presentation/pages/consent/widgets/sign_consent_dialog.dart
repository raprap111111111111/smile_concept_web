// lib/presentation/pages/consent/widgets/sign_consent_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/consent/consent_form_data.dart';
import '../../../../data/models/consent/consent_sign_request.dart';
import '../../../../data/models/patient/patient_model.dart';
import '../../../providers/consent/consent_provider.dart';
import '../../../providers/consent/sign_consent_form_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/shared/app_snackbar.dart';

import 'signature_pad_widget.dart';
import 'step_indicator.dart';

// ─── Step widgets ────────────────────────────────────────────────────────
import 'steps/step_0_patient_picker.dart';
import 'steps/step_1_patient_info.dart';
import 'steps/step_2_medical_history.dart';
import 'steps/step_3_consent_clauses.dart';
import 'steps/step_4_intraoral.dart';
import 'steps/step_5_signature.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Step metadata
// ═══════════════════════════════════════════════════════════════════════════
const _kStepLabels = ['Patient', 'Info', 'Medical', 'Consent', 'Intraoral', 'Sign'];
const _kStepTitles = [
  'Select Patient',
  'Patient Information',
  'Medical History',
  'Consent Acknowledgement',
  'Intraoral Examination',
  'Patient Signature',
];

// ═══════════════════════════════════════════════════════════════════════════
// SignConsentDialog — thin shell that routes to step widgets
// ═══════════════════════════════════════════════════════════════════════════
class SignConsentDialog extends ConsumerStatefulWidget {
  final PatientModel? preselectedPatient;
  final int? appointmentId;

  const SignConsentDialog({
    super.key,
    this.preselectedPatient,
    this.appointmentId,
  });

  static Future<bool?> show(
    BuildContext context, {
    PatientModel? preselectedPatient,
    int? appointmentId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SignConsentDialog(
        preselectedPatient: preselectedPatient,
        appointmentId: appointmentId,
      ),
    );
  }

  @override
  ConsumerState<SignConsentDialog> createState() =>
      _SignConsentDialogState();
}

class _SignConsentDialogState extends ConsumerState<SignConsentDialog> {
  final _sigKey = GlobalKey<SignaturePadWidgetState>();
  int _step = 0;

  @override
  void initState() {
    super.initState();

    // Reset form + pre-select patient after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(consentFormProvider.notifier);
      notifier.reset();

      if (widget.preselectedPatient != null) {
        notifier.selectPatient(widget.preselectedPatient!);
        setState(() => _step = 1);
      }
    });
  }

  // ═════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final action = ref.watch(consentActionProvider);

    ref.listen(consentActionProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        AppSnackbar.show(context, next.error!, isError: true);
      }
    });

    return Dialog(
      insetPadding: const EdgeInsets.all(AppDimensions.paddingLarge),
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 850),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.divider),
            ConsentStepIndicator(
              currentStep: _step,
              labels: _kStepLabels,
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(child: _buildBody()),
            const Divider(height: 1, color: AppColors.divider),
            _buildFooter(action.isSubmitting),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  // Header
  // ═════════════════════════════════════════════════════════
  Widget _buildHeader() {
    final patient = ref.watch(consentFormProvider).selectedPatient;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.primaryDark,
              size: AppDimensions.iconSizeMedium,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_kStepTitles[_step],
                    style: AppTextStyles.titleMedium),
                if (patient != null)
                  Text('Patient: ${patient.name}',
                      style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  // Body — route to step widgets
  // ═════════════════════════════════════════════════════════
  Widget _buildBody() => switch (_step) {
        0 => const Step0PatientPicker(),
        1 => const Step1PatientInfo(),
        2 => const Step2MedicalHistory(),
        3 => const Step3ConsentClauses(),
        4 => const Step4Intraoral(),
        5 => Step5Signature(sigKey: _sigKey),
        _ => const SizedBox.shrink(),
      };

  // ═════════════════════════════════════════════════════════
  // Footer
  // ═════════════════════════════════════════════════════════
  Widget _buildFooter(bool isSubmitting) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_step > 0)
            TextButton.icon(
              onPressed:
                  isSubmitting ? null : () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isSubmitting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          _buildPrimaryButton(isSubmitting),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(bool isSubmitting) {
    if (_step < 5) {
      final canProceed = _canProceedFromStep(_step);
      return FilledButton.icon(
        onPressed: canProceed ? () => setState(() => _step++) : null,
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text('Continue'),
        style:
            FilledButton.styleFrom(backgroundColor: AppColors.primary),
      );
    }
    return FilledButton.icon(
      onPressed: isSubmitting ? null : _submit,
      icon: isSubmitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textOnPrimary,
              ),
            )
          : const Icon(Icons.check, size: 18),
      label: Text(isSubmitting ? 'Submitting…' : 'Sign & Submit'),
      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
    );
  }

  // ═════════════════════════════════════════════════════════
  // Validation per step
  // ═════════════════════════════════════════════════════════
  bool _canProceedFromStep(int step) {
    final state = ref.watch(consentFormProvider);
    final notifier = ref.read(consentFormProvider.notifier);

    return switch (step) {
      0 => state.selectedPatient != null,
      1 => state.name.trim().isNotEmpty,
      2 => true,
      3 => notifier.allClausesAgreed(),
      4 => true,
      _ => true,
    };
  }

  // ═════════════════════════════════════════════════════════
  // Submit
  // ═════════════════════════════════════════════════════════
  Future<void> _submit() async {
    // Force any text field to flush its latest value
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final sig = _sigKey.currentState;
    if (sig == null || sig.isEmpty) {
      AppSnackbar.show(context, 'Please provide a signature.',
          isError: true);
      return;
    }

    final notifier = ref.read(consentFormProvider.notifier);
    if (!notifier.allClausesAgreed()) {
      AppSnackbar.show(
        context,
        'Please acknowledge all ${kConsentClauses.length} clauses first.',
        isError: true,
      );
      return;
    }

    final base64 = await sig.exportBase64();
    if (base64 == null) return;

    final state = ref.read(consentFormProvider);
    final patient = state.selectedPatient!;
    final signerRole = switch (state.signerRole) {
      SignerRole.self => 'self',
      SignerRole.guardian => 'guardian',
      SignerRole.staff => 'staff',
    };

    final payload = notifier.buildFormPayload();

    debugPrint('🔵 SIGN → patient=${patient.name} (id=${patient.userId}) '
        'role=$signerRole '
        'patient_info=${payload['patient_info']}');

    final result = await ref
        .read(consentActionProvider.notifier)
        .sign(
          ConsentSignRequest(
            consentTemplateId: 1,
            userId: patient.userId,
            appointmentId: widget.appointmentId,
            signatureData: base64,
            formData: payload,
            signOnBehalfOf: signerRole,
          ),
        );

    if (result != null && mounted) {
      Navigator.of(context).pop(true);
      AppSnackbar.show(context, 'Consent signed successfully.');
    }
  }
}