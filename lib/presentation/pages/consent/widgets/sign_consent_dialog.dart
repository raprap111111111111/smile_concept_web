import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';  
import '../../../../data/models/consent/consent_sign_request.dart';
import '../../../../data/models/consent/consent_template_model.dart';
import '../../../../data/models/patient/patient_model.dart';
import '../../../providers/consent/consent_provider.dart';
import '../../../providers/consent/consent_templates_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/shared/app_snackbar.dart';
import 'signature_pad_widget.dart';

/// Local-only provider: fetches patients on demand for the picker.
/// Uses your existing dio client — no dependency on a patients provider file.
final _dialogPatientsProvider =
    FutureProvider.autoDispose.family<List<PatientModel>, String>(
  (ref, search) async {
    final dio = ref.watch(dioProvider);   // ← use YOUR dio provider name

    final response = await dio.get(
      '/patients',
      queryParameters: {
        'page': 1,
        'per_page': 30,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    // Adjust based on your API envelope. Common shapes:
    //   { "data": [ ... ] }
    //   { "data": { "data": [ ... ] } }        (Laravel paginator wrapped)
    //   { "data": { "records": [ ... ] } }
    final body = response.data;
    final list = (body['data'] is List)
        ? body['data'] as List
        : (body['data']?['data'] ?? body['data']?['records'] ?? []) as List;

    return list
        .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

/// Sign flow (staff facilitates, patient signs):
///   Step 0 → pick PATIENT       (skipped if patient preselected)
///   Step 1 → pick TEMPLATE
///   Step 2 → review + patient signs
class SignConsentDialog extends ConsumerStatefulWidget {
  final PatientModel? preselectedPatient;
  final int?          appointmentId;

  const SignConsentDialog({
    super.key,
    this.preselectedPatient,
    this.appointmentId,
  });

  static Future<bool?> show(
    BuildContext context, {
    PatientModel? preselectedPatient,
    int?          appointmentId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SignConsentDialog(
        preselectedPatient: preselectedPatient,
        appointmentId:      appointmentId,
      ),
    );
  }

  @override
  ConsumerState<SignConsentDialog> createState() => _SignConsentDialogState();
}

class _SignConsentDialogState extends ConsumerState<SignConsentDialog> {
  final _sigKey        = GlobalKey<SignaturePadWidgetState>();
  final _patientSearch = TextEditingController();

  PatientModel?         _selectedPatient;
  ConsentTemplateModel? _selectedTemplate;
  int                   _step = 0;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatient != null) {
      _selectedPatient = widget.preselectedPatient;
      _step = 1;
    }
  }

  @override
  void dispose() {
    _patientSearch.dispose();
    super.dispose();
  }

  // ─── build ──────────────────────────────────────────────────────────────
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
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(child: _buildBody()),
            const Divider(height: 1, color: AppColors.divider),
            _buildFooter(action.isSubmitting),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────
  String get _stepTitle {
    switch (_step) {
      case 0: return 'Select Patient';
      case 1: return 'Select Consent Form';
      case 2: return 'Review & Sign';
      default: return '';
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
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
                Text(_stepTitle, style: AppTextStyles.titleMedium),
                if (_selectedPatient != null)
                  Text(
                    'Patient: ${_selectedPatient!.name}',
                    style: AppTextStyles.labelSmall,
                  ),
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

  // ─── Body ───────────────────────────────────────────────────────────────
  Widget _buildBody() {
    switch (_step) {
      case 0: return _buildPatientPicker();
      case 1: return _buildTemplatePicker();
      case 2: return _buildSignStep();
      default: return const SizedBox();
    }
  }

  // ─── Step 0 — pick PATIENT ──────────────────────────────────────────────
  Widget _buildPatientPicker() {
    final patientsAsync =
        ref.watch(_dialogPatientsProvider(_patientSearch.text));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: TextField(
            controller: _patientSearch,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search patient by name…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: patientsAsync.when(
            loading: () => const LoadingWidget(message: 'Loading patients…'),
            error:   (e, _) => Center(child: Text('Failed: $e')),
            data:    (patients) {
              if (patients.isEmpty) {
                return const Center(child: Text('No patients found.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                ),
                itemCount: patients.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = patients[i];
                  final selected = _selectedPatient?.id == p.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: selected
                          ? AppColors.primary
                          : AppColors.accentLight,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: selected
                              ? AppColors.textOnPrimary
                              : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    title:    Text(p.name),
                    subtitle: Text(p.email),
                    trailing: selected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () => setState(() => _selectedPatient = p),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Step 1 — pick TEMPLATE ─────────────────────────────────────────────
  Widget _buildTemplatePicker() {
    final templatesAsync = ref.watch(consentTemplatesProvider);
    return templatesAsync.when(
      loading: () => const LoadingWidget(message: 'Loading templates…'),
      error:   (e, _) => _buildErrorState(e.toString()),
      data:    (templates) => _buildTemplateList(templates),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text('Failed to load templates', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppDimensions.paddingMedium),
            FilledButton.icon(
              onPressed: () => ref.invalidate(consentTemplatesProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateList(List<ConsentTemplateModel> templates) {
    if (templates.isEmpty) {
      return const Center(child: Text('No active consent templates'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      itemCount: templates.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.paddingSmall),
      itemBuilder: (context, index) {
        final template = templates[index];
        final selected = _selectedTemplate?.id == template.id;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedTemplate = template),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentLight : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.title, style: AppTextStyles.titleSmall),
                        const SizedBox(height: 2),
                        Text(template.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Step 2 — SIGN ──────────────────────────────────────────────────────
  Widget _buildSignStep() {
    final template = _selectedTemplate!;
    final patient  = _selectedPatient!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppDimensions.paddingSmall),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Text(template.body,
                        style: AppTextStyles.bodyMedium),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          Row(
            children: [
              const Icon(Icons.draw_outlined,
                  color: AppColors.primary,
                  size: AppDimensions.iconSizeMedium),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text('Patient Signature', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          SignaturePadWidget(key: _sigKey),
          const SizedBox(height: AppDimensions.paddingMedium),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.warning,
                    size: AppDimensions.iconSizeSmall),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Text(
                    'By signing, ${patient.name} acknowledges '
                    'reading and agreeing to this consent.',
                    style: AppTextStyles.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Footer ─────────────────────────────────────────────────────────────
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
          const SizedBox(width: AppDimensions.paddingSmall),
          TextButton(
            onPressed:
                isSubmitting ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          _buildPrimaryButton(isSubmitting),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(bool isSubmitting) {
    if (_step == 0) {
      return FilledButton.icon(
        onPressed: _selectedPatient == null
            ? null
            : () => setState(() => _step = 1),
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text('Continue'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
      );
    }
    if (_step == 1) {
      return FilledButton.icon(
        onPressed: _selectedTemplate == null
            ? null
            : () => setState(() => _step = 2),
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text('Continue'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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

  // ─── Submit ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final sig = _sigKey.currentState;
    if (sig == null || sig.isEmpty) {
      AppSnackbar.show(
        context,
        'Please provide a signature to continue.',
        isError: true,
      );
      return;
    }

    final base64 = await sig.exportBase64();
    if (base64 == null) return;

    final patient = _selectedPatient!;
    debugPrint(
      '🔵 SIGN → patientUserId=${patient.userId}, patientName=${patient.name}',
    );

    final result = await ref.read(consentActionProvider.notifier).sign(
          ConsentSignRequest(
            consentTemplateId: _selectedTemplate!.id,
            userId:            patient.userId,
            appointmentId:     widget.appointmentId,
            signatureData:     base64,
          ),
        );

    if (result != null && mounted) {
      Navigator.of(context).pop(true);
      AppSnackbar.show(context, 'Consent signed successfully.');
    }
  }
}