import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/models/consent/consent_form_data.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_dimensions.dart';
import '../../../../theme/app_text_styles.dart';
import '/presentation/pages/consent/widgets/section_title.dart';
import '/presentation/providers/consent/sign_consent_form_provider.dart';

class Step3ConsentClauses extends ConsumerWidget {
  const Step3ConsentClauses({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consentFormProvider);
    final notifier = ref.read(consentFormProvider.notifier);
    final defaultInitials =
        notifier.getInitials(state.selectedPatient?.name ?? '');

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
                Text('Consent Clauses', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppDimensions.paddingSmall),
                Text(
                  'Please acknowledge each clause by checking the box '
                  'and providing your initials.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      notifier.autoFillInitials(defaultInitials),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: AppColors.surface,
                  ),
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: Text('Auto-fill all with "$defaultInitials"'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: notifier.clearAllClauses,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: AppColors.surface,
                ),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const SectionTitle(
            title: 'Acknowledge Each Clause',
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 4),
          Text(
            'Patient must initial each clause to indicate they read '
            'and understand it.',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          ...kConsentClauses.map(
            (clause) => _ClauseRow(
              clauseKey: clause['key']!,
              title: clause['title']!,
              agreed: state.clauseAgreed[clause['key']!] ?? false,
              initial: state.clauseInitials[clause['key']!] ?? '',
              onAgreedChanged: (v) =>
                  notifier.toggleClause(clause['key']!, v),
              onInitialChanged: (v) =>
                  notifier.setClauseInitial(clause['key']!, v),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClauseRow extends StatefulWidget {
  final String clauseKey;
  final String title;
  final bool agreed;
  final String initial;
  final ValueChanged<bool> onAgreedChanged;
  final ValueChanged<String> onInitialChanged;

  const _ClauseRow({
    required this.clauseKey,
    required this.title,
    required this.agreed,
    required this.initial,
    required this.onAgreedChanged,
    required this.onInitialChanged,
  });

  @override
  State<_ClauseRow> createState() => _ClauseRowState();
}

class _ClauseRowState extends State<_ClauseRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(_ClauseRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != _ctrl.text) {
      _ctrl.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: widget.agreed
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.agreed
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: widget.agreed,
            onChanged: (v) => widget.onAgreedChanged(v ?? false),
            activeColor: AppColors.success,
            side: const BorderSide(color: AppColors.border),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              maxLength: 5,
              textCapitalization: TextCapitalization.characters,
              onChanged: widget.onInitialChanged,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Initial',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}