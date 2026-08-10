import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../data/models/consent/patient_consent_model.dart';
import '../../../data/repositories/consent_repository.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/consent/consent_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/error_display_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/shared/app_snackbar.dart';
import '../../widgets/shared/hold_to_delete_button.dart';
import '../../widgets/shared/pdf_viewer_page.dart';

/// Loads a single consent by ID.
final consentByIdProvider =
    FutureProvider.family<PatientConsentModel, int>((ref, id) async {
  return ref.watch(consentRepositoryProvider).getConsent(id);
});

class ConsentDetailPage extends ConsumerWidget {
  final int consentId;

  const ConsentDetailPage({
    super.key,
    required this.consentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentAsync = ref.watch(consentByIdProvider(consentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consent Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(consentByIdProvider(consentId)),
          ),
        ],
      ),
      body: consentAsync.when(
        loading: () => const LoadingWidget(message: 'Loading consent...'),
        error: (e, _) => ErrorDisplayWidget(
          error: e.toString(),
          onRetry: () => ref.invalidate(consentByIdProvider(consentId)),
        ),
        data: (consent) => _buildBody(context, ref, consent),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PatientConsentModel consent,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(context, ref, consent),
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildInfoCard(consent),
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildConsentBody(consent),
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildSignatureCard(consent),
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildActionsCard(context, ref, consent),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeaderCard(
    BuildContext context,
    WidgetRef ref,
    PatientConsentModel consent,
  ) {
    final voided = consent.isVoided;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: Icon(
              voided ? Icons.cancel : Icons.assignment_turned_in,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consent.template?.title ?? 'Untitled Consent',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voided
                      ? 'Signed then voided'
                      : 'Legally binding signed document',
                  style: AppTextStyles.bodyOnDark,
                ),
              ],
            ),
          ),
          if (voided)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'VOIDED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Info Grid ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard(PatientConsentModel consent) {
    final dateFmt = DateFormat('MMMM d, y • h:mm a');

    return _buildCard(
      title: 'Details',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _infoRow(
            Icons.person_outline,
            'Patient',
            consent.patient?.name ?? '—',
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            'Signed',
            dateFmt.format(consent.signedAt.toLocal()),
          ),
          if (consent.signedByStaff != null)
            _infoRow(
              Icons.badge_outlined,
              'Witnessed by',
              consent.signedByStaff!.name,
            ),
          if (consent.appointment != null)
            _infoRow(
              Icons.event_outlined,
              'Appointment',
              '#${consent.appointment!.id}',
            ),
          if (consent.ipAddress != null)
            _infoRow(
              Icons.language_outlined,
              'IP Address',
              consent.ipAddress!,
            ),
          if (consent.isVoided) ...[
            const Divider(
              height: AppDimensions.paddingLarge,
              color: AppColors.divider,
            ),
            _infoRow(
              Icons.block,
              'Voided at',
              consent.voidedAt != null
                  ? dateFmt.format(consent.voidedAt!.toLocal())
                  : '—',
              color: AppColors.error,
            ),
            if (consent.voidedReason != null)
              _infoRow(
                Icons.notes_outlined,
                'Reason',
                consent.voidedReason!,
                color: AppColors.error,
              ),
          ],
        ],
      ),
    );
  }

  // ─── Consent Body ──────────────────────────────────────────────────────────
  Widget _buildConsentBody(PatientConsentModel consent) {
    final body = consent.template?.body ?? 'No consent text available.';

    return _buildCard(
      title: 'Consent Text',
      icon: Icons.article_outlined,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          child: Text(body, style: AppTextStyles.bodyMedium),
        ),
      ),
    );
  }

  // ─── Signature ─────────────────────────────────────────────────────────────
  Widget _buildSignatureCard(PatientConsentModel consent) {
    final sig = consent.signatureData;

    return _buildCard(
      title: 'Signature',
      icon: Icons.draw_outlined,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            if (sig != null && sig.startsWith('data:image'))
              _buildSignatureImage(sig)
            else
              _buildNoSignaturePlaceholder(),
            const SizedBox(height: AppDimensions.paddingMedium),
            Container(
              width: double.infinity,
              height: 1,
              color: AppColors.border,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              consent.patient?.name ?? 'Patient signature',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureImage(String dataUri) {
    try {
      return Image.memory(
        Uri.parse(dataUri).data!.contentAsBytes(),
        height: 140,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildNoSignaturePlaceholder(),
      );
    } catch (_) {
      return _buildNoSignaturePlaceholder();
    }
  }

  Widget _buildNoSignaturePlaceholder() {
    return Container(
      height: 140,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            'Signature image not available',
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────
  Widget _buildActionsCard(
    BuildContext context,
    WidgetRef ref,
    PatientConsentModel consent,
  ) {
    final perm = ref.watch(permissionServiceProvider);
    final canPrint = perm.canAny([
      Perm.consentFormPrint,
      Perm.consentFormViewOwn,
      Perm.consentFormViewAny,
    ]);
    final canVoid =
        perm.can(Perm.consentFormVoid) && !consent.isVoided;

    return _buildCard(
      title: 'Actions',
      icon: Icons.settings_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canPrint) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View PDF'),
                    onPressed: () => _openPdf(context, consent),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    onPressed: () => _openPdf(context, consent),
                  ),
                ),
              ],
            ),
          ],
          if (canVoid) ...[
            const SizedBox(height: AppDimensions.paddingLarge),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppDimensions.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      Text(
                        'Void Consent',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingXS),
                  Text(
                    'Voiding is permanent and requires a reason. '
                    'The document will remain viewable but marked as invalid.',
                    style: AppTextStyles.labelSmall,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  HoldToDeleteButton(
                    label: 'Hold to void',
                    hintText: 'hold 2s to void this consent',
                    onComplete: () =>
                        _showVoidDialog(context, ref, consent),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.cardPaddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text(title, style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
          const SizedBox(width: AppDimensions.paddingSmall),
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.labelSmall),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: color ?? AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPdf(BuildContext context, PatientConsentModel consent) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          title: consent.template?.title ?? 'Consent PDF',
          consentId: consent.id,
        ),
      ),
    );
  }

  Future<void> _showVoidDialog(
    BuildContext context,
    WidgetRef ref,
    PatientConsentModel consent,
  ) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text('Void Consent', style: AppTextStyles.titleMedium),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone. Please provide a reason:',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              TextFormField(
                controller: reasonController,
                autofocus: true,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Patient requested cancellation of procedure',
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 5)
                        ? 'Please provide a reason (min 5 characters)'
                        : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Void Consent'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(consentActionProvider.notifier)
        .voidConsent(consent.id, reasonController.text.trim());

    if (result != null && context.mounted) {
      AppSnackbar.show(context, 'Consent voided successfully.');
      ref.invalidate(consentByIdProvider(consent.id));
    }
  }
}