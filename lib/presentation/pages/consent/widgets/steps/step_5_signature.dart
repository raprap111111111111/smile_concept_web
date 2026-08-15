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
          // ─── Signer Role ────────────────────────────────────────────────
          const SectionTitle(
            title: 'Who is signing?',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 8),

          // ✅ NEW: single RadioGroup wrapping all radios
          RadioGroup<SignerRole>(
            groupValue: state.signerRole,
            onChanged: (v) {
              if (v != null) notifier.setSignerRole(v);
            },
            child: Column(
              children: [
                RadioListTile<SignerRole>(
                  value: SignerRole.self,
                  title: Text('Patient ($patientName)'),
                  subtitle: const Text('Patient signs for themselves'),
                  dense: true,
                ),
                RadioListTile<SignerRole>(
                  value: SignerRole.guardian,
                  title: const Text('Parent / Guardian'),
                  subtitle: const Text('Guardian signs on behalf of minor'),
                  dense: true,
                ),
                RadioListTile<SignerRole>(
                  value: SignerRole.staff,
                  title: const Text('Staff Witnessed'),
                  subtitle: const Text('Staff facilitated signing'),
                  dense: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── Signature Pad ──────────────────────────────────────────────
          SectionTitle(
            title: switch (state.signerRole) {
              SignerRole.self     => 'Patient Signature',
              SignerRole.guardian => 'Guardian Signature',
              SignerRole.staff    => 'Signature',
            },
            icon: Icons.draw_outlined,
          ),
          const SizedBox(height: 8),
          SignaturePadWidget(key: sigKey),
          const SizedBox(height: 16),

          // ─── Disclaimer ─────────────────────────────────────────────────
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
}