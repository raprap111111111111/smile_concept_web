import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smile_concept_web/data/models/consent/consent_form_data.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/theme/app_dimensions.dart';
import 'package:smile_concept_web/presentation/theme/app_text_styles.dart';
import 'package:smile_concept_web/presentation/pages/consent/widgets/section_title.dart';
import 'package:smile_concept_web/presentation/pages/consent/widgets/signature_pad_widget.dart';
import 'package:smile_concept_web/presentation/providers/consent/sign_consent_form_provider.dart';

class Step5Signature extends ConsumerWidget {
  final GlobalKey<SignaturePadWidgetState> sigKey;

  const Step5Signature({super.key, required this.sigKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consentFormProvider);
    final notifier = ref.read(consentFormProvider.notifier);
    final patientName = state.selectedPatient?.name ?? 'Patient';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Who is signing?',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 8),

          // Light themed radio cards
          _SignerOption(
            selected: state.signerRole == SignerRole.self,
            title: 'Patient ($patientName)',
            subtitle: 'Patient signs for themselves',
            onTap: () => notifier.setSignerRole(SignerRole.self),
          ),
          const SizedBox(height: 8),
          _SignerOption(
            selected: state.signerRole == SignerRole.guardian,
            title: 'Parent / Guardian',
            subtitle: 'Guardian signs on behalf of minor',
            onTap: () => notifier.setSignerRole(SignerRole.guardian),
          ),
          const SizedBox(height: 8),
          _SignerOption(
            selected: state.signerRole == SignerRole.staff,
            title: 'Staff Witnessed',
            subtitle: 'Staff facilitated signing',
            onTap: () => notifier.setSignerRole(SignerRole.staff),
          ),

          const SizedBox(height: 20),

          SectionTitle(
            title: switch (state.signerRole) {
              SignerRole.self => 'Patient Signature',
              SignerRole.guardian => 'Guardian Signature',
              SignerRole.staff => 'Signature',
            },
            icon: Icons.draw_outlined,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: SignaturePadWidget(key: sigKey),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: AppDimensions.iconSizeSmall,
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Text(
                    'By signing, I acknowledge reading, understanding, '
                    'and agreeing to all clauses, medical information, '
                    'and intraoral findings provided in this consent form.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
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

class _SignerOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SignerOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentLight : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}