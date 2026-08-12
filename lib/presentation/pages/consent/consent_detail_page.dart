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

final consentByIdProvider =
    FutureProvider.family<PatientConsentModel, int>((ref, id) async {
  return ref.watch(consentRepositoryProvider).getConsent(id);
});

class ConsentDetailPage extends ConsumerWidget {
  final int consentId;
  const ConsentDetailPage({super.key, required this.consentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentAsync = ref.watch(consentByIdProvider(consentId));

    return Scaffold(
      backgroundColor: AppColors.surface,
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
              _DetailPageHeader(
                onBack: () => Navigator.of(context).pop(),
                onRefresh: () => ref.invalidate(consentByIdProvider(consentId)),
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
              _HeroBanner(consent: consent),
              const SizedBox(height: AppDimensions.paddingLarge),
              _MetadataGrid(consent: consent),
              const SizedBox(height: AppDimensions.paddingLarge),
              _ConsentTextSection(consent: consent),
              const SizedBox(height: AppDimensions.paddingLarge),
              _SignatureSection(consent: consent),
              const SizedBox(height: AppDimensions.paddingLarge),
              _ActionsSection(consent: consent),
              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DETAIL PAGE HEADER — Back button + refresh (no dark AppBar)
// ═══════════════════════════════════════════════════════════════════════════
class _DetailPageHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _DetailPageHeader({
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSmall,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Back to consents',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Tooltip(
          message: 'Refresh',
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
                onTap: onRefresh,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO BANNER — top-of-page identity card
// ═══════════════════════════════════════════════════════════════════════════
class _HeroBanner extends StatelessWidget {
  final PatientConsentModel consent;
  const _HeroBanner({required this.consent});

  @override
  Widget build(BuildContext context) {
    final voided = consent.isVoided;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: voided
            ? const LinearGradient(
                colors: [
                  AppColors.textSecondary,
                  AppColors.ink,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: (voided ? AppColors.ink : AppColors.primary)
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: Icon(
              voided ? Icons.cancel_outlined : Icons.verified_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consent.template?.title ?? 'Untitled Consent',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      voided ? Icons.block_outlined : Icons.shield_outlined,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        voided
                            ? 'This consent has been voided'
                            : 'Legally binding signed document',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),

          // Status badge
          _StatusBadge(voided: voided),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool voided;
  const _StatusBadge({required this.voided});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            voided ? 'VOIDED' : 'ACTIVE',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// METADATA GRID
// ═══════════════════════════════════════════════════════════════════════════
class _MetadataGrid extends StatelessWidget {
  final PatientConsentModel consent;
  const _MetadataGrid({required this.consent});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final tiles = <Widget>[
                  _MetaTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Patient',
                    value: consent.patient?.name ?? '—',
                  ),
                  _MetaTile(
                    icon: Icons.event_outlined,
                    label: 'Signed on',
                    value: dateFmt.format(consent.signedAt.toLocal()),
                  ),
                  if (consent.signedByStaff != null)
                    _MetaTile(
                      icon: Icons.badge_outlined,
                      label: 'Witnessed by',
                      value: consent.signedByStaff!.name,
                    ),
                  if (consent.appointment != null)
                    _MetaTile(
                      icon: Icons.event_note_outlined,
                      label: 'Appointment',
                      value: '#${consent.appointment!.id}',
                    ),
                  if (consent.ipAddress != null)
                    _MetaTile(
                      icon: Icons.language_outlined,
                      label: 'IP Address',
                      value: consent.ipAddress!,
                    ),
                ];

                return Wrap(
                  spacing: AppDimensions.paddingMedium,
                  runSpacing: AppDimensions.paddingMedium,
                  children: tiles.map((tile) {
                    return SizedBox(
                      width: isNarrow
                          ? constraints.maxWidth
                          : (constraints.maxWidth / 2) -
                              (AppDimensions.paddingMedium / 2) -
                              AppDimensions.paddingMedium,
                      child: tile,
                    );
                  }).toList(),
                );
              },
            ),
          ),
          if (consent.isVoided) _VoidInfoBanner(consent: consent),
        ],
      ),
    );
  }
}

class _VoidInfoBanner extends StatelessWidget {
  final PatientConsentModel consent;
  const _VoidInfoBanner({required this.consent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.statusCancelledSoft,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.borderRadiusLarge),
          bottomRight: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.block_outlined,
                color: AppColors.statusCancelledInk,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Void Information',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.statusCancelledInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          if (consent.voidedAt != null)
            _VoidRow(
              icon: Icons.schedule_outlined,
              label: 'Voided on',
              value: DateFormat('MMM d, yyyy • h:mm a')
                  .format(consent.voidedAt!.toLocal()),
            ),
          if (consent.voidedReason != null) ...[
            const SizedBox(height: AppDimensions.paddingXS),
            _VoidRow(
              icon: Icons.notes_outlined,
              label: 'Reason',
              value: consent.voidedReason!,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoidRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _VoidRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.statusCancelledInk),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.statusCancelledInk,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.statusCancelledInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONSENT TEXT
// ═══════════════════════════════════════════════════════════════════════════
class _ConsentTextSection extends StatelessWidget {
  final PatientConsentModel consent;
  const _ConsentTextSection({required this.consent});

  @override
  Widget build(BuildContext context) {
    final body = consent.template?.body ?? 'No consent text available.';

    return _SectionCard(
      icon: Icons.description_outlined,
      title: 'Consent Text',
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: SelectableText(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.ink,
                height: 1.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIGNATURE
// ═══════════════════════════════════════════════════════════════════════════
class _SignatureSection extends StatelessWidget {
  final PatientConsentModel consent;
  const _SignatureSection({required this.consent});

  @override
  Widget build(BuildContext context) {
    final sig = consent.signatureData;
    final hasSig = sig != null && sig.startsWith('data:image');

    return _SectionCard(
      icon: Icons.draw_outlined,
      title: 'Digital Signature',
      trailing: hasSig ? const _VerifiedBadge() : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            if (hasSig)
              _SignatureImage(dataUri: sig)
            else
              const _NoSignaturePlaceholder(),
            const SizedBox(height: AppDimensions.paddingMedium),
            Container(
              width: double.infinity,
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.border,
                    AppColors.border,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              consent.patient?.name ?? 'Patient signature',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Signed on ${DateFormat('MMM d, yyyy').format(consent.signedAt.toLocal())}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusCompletedSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 12,
            color: AppColors.statusCompletedInk,
          ),
          const SizedBox(width: 4),
          Text(
            'VERIFIED',
            style: TextStyle(
              color: AppColors.statusCompletedInk,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureImage extends StatelessWidget {
  final String dataUri;
  const _SignatureImage({required this.dataUri});

  @override
  Widget build(BuildContext context) {
    try {
      return Image.memory(
        Uri.parse(dataUri).data!.contentAsBytes(),
        height: 140,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const _NoSignaturePlaceholder(),
      );
    } catch (_) {
      return const _NoSignaturePlaceholder();
    }
  }
}

class _NoSignaturePlaceholder extends StatelessWidget {
  const _NoSignaturePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.gesture_outlined,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            'Signature not available',
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIONS
// ═══════════════════════════════════════════════════════════════════════════
class _ActionsSection extends ConsumerWidget {
  final PatientConsentModel consent;
  const _ActionsSection({required this.consent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = ref.watch(permissionServiceProvider);
    final canPrint = perm.canAny([
      Perm.consentFormPrint,
      Perm.consentFormViewOwn,
      Perm.consentFormViewAny,
    ]);
    final canVoid = perm.can(Perm.consentFormVoid) && !consent.isVoided;

    if (!canPrint && !canVoid) return const SizedBox.shrink();

    return _SectionCard(
      icon: Icons.tune_rounded,
      title: 'Actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canPrint)
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.visibility_outlined,
                    label: 'View PDF',
                    isPrimary: false,
                    onPressed: () => _openPdf(context),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.download_outlined,
                    label: 'Download',
                    isPrimary: true,
                    onPressed: () => _openPdf(context),
                  ),
                ),
              ],
            ),
          if (canVoid) ...[
            if (canPrint) const SizedBox(height: AppDimensions.paddingLarge),
            _VoidZone(consent: consent),
          ],
        ],
      ),
    );
  }

  void _openPdf(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          title: consent.template?.title ?? 'Consent PDF',
          consentId: consent.id,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      icon: Icon(icon, size: 18, color: AppColors.primaryDark),
      label: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
      onPressed: onPressed,
    );
  }
}

class _VoidZone extends ConsumerWidget {
  final PatientConsentModel consent;
  const _VoidZone({required this.consent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.statusCancelledSoft,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.statusCancelledInk,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text(
                'Danger Zone',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.statusCancelledInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Voiding this consent is permanent and cannot be undone. '
            'The document will remain accessible but marked as invalid.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.statusCancelledInk,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          HoldToDeleteButton(
            label: 'Hold to void',
            hintText: 'hold 2 seconds to confirm',
            onComplete: () => _handleVoid(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVoid(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _VoidConsentDialog(),
    );

    if (reason == null || !context.mounted) return;

    final result = await ref
        .read(consentActionProvider.notifier)
        .voidConsent(consent.id, reason);

    if (!context.mounted) return;

    if (result != null) {
      AppSnackbar.show(context, 'Consent voided successfully.');
      ref.invalidate(consentByIdProvider(consent.id));
    } else {
      final error = ref.read(consentActionProvider).error;
      AppSnackbar.show(
        context,
        error ?? 'Failed to void consent. Please try again.',
        isError: true,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED SECTION CARD
// ═══════════════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Text(title, style: AppTextStyles.titleSmall),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VOID CONSENT DIALOG
// ═══════════════════════════════════════════════════════════════════════════
class _VoidConsentDialog extends StatefulWidget {
  const _VoidConsentDialog();

  @override
  State<_VoidConsentDialog> createState() => _VoidConsentDialogState();
}

class _VoidConsentDialogState extends State<_VoidConsentDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.statusCancelledSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.statusCancelledInk,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Void Consent', style: AppTextStyles.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'This action cannot be undone',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingLarge),

                // Reason input
                Text(
                  'REASON FOR VOIDING',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 500,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Patient requested cancellation of procedure',
                    hintStyle: AppTextStyles.inputHint,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius,
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'Please provide at least 5 characters'
                      : null,
                ),
                const SizedBox(height: AppDimensions.paddingLarge),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.block_outlined, size: 18),
                      label: const Text('Void Consent'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingLarge,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}