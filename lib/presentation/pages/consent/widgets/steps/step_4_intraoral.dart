import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../../data/models/consent/consent_form_data.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_dimensions.dart';
import '../../../../theme/app_text_styles.dart';
import '/presentation/widgets/shared/app_snackbar.dart';
import '/presentation/pages/consent/widgets/section_title.dart';
import '/presentation/providers/consent/sign_consent_form_provider.dart';

class Step4Intraoral extends ConsumerWidget {
  const Step4Intraoral({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consentFormProvider);
    final notifier = ref.read(consentFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Intraoral Examination',
            icon: Icons.medical_services_outlined,
          ),
          const SizedBox(height: 4),
          Text(
            'Select a condition from the legend, '
            'then tap a tooth to assign it.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // ── Legend ───────────────────────────────────────────────────────
          const SectionTitle(
            title: 'Legend / Conditions',
            icon: Icons.list_alt,
          ),
          const SizedBox(height: 8),
          _IntraoralLegendWrap(
            selectedKey: state.selectedIntraoralConditionKey,
            onSelect: notifier.selectIntraoralCondition,
          ),
          const SizedBox(height: 16),

          // ── Permanent Teeth ──────────────────────────────────────────────
          const SectionTitle(
            title: 'Permanent Teeth',
            icon: Icons.grid_3x3,
          ),
          const SizedBox(height: 8),
          _TeethGrid(
            teeth: kPermanentTeeth.map((t) => t.toString()).toList(),
            selections: state.intraoralSelections,
            onTap: (tooth) => _handleToothTap(
              context,
              ref,
              tooth,
              state.selectedIntraoralConditionKey,
              notifier,
            ),
          ),
          const SizedBox(height: 16),

          // ── Primary Teeth ────────────────────────────────────────────────
          const SectionTitle(
            title: 'Primary / Deciduous Teeth (A–T)',
            icon: Icons.grid_4x4,
          ),
          const SizedBox(height: 8),
          _TeethGrid(
            teeth: kPrimaryTeeth,
            selections: state.intraoralSelections,
            onTap: (tooth) => _handleToothTap(
              context,
              ref,
              tooth,
              state.selectedIntraoralConditionKey,
              notifier,
            ),
          ),
        ],
      ),
    );
  }

  void _handleToothTap(
    BuildContext context,
    WidgetRef ref,
    String tooth,
    String? selectedKey,
    ConsentFormNotifier notifier,
  ) {
    if (selectedKey == null) {
      AppSnackbar.show(
        context,
        'Select a condition from the legend first.',
        isError: false,
      );
      return;
    }
    final cond = kIntraoralLegend.firstWhere(
      (c) => c.key == selectedKey,
      orElse: () => kIntraoralLegend.first,
    );
    notifier.assignToothCondition(tooth, cond.symbol);
  }
}

// ─── Legend wrap ─────────────────────────────────────────────────────────────
class _IntraoralLegendWrap extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  const _IntraoralLegendWrap({
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: kIntraoralLegend.map((cond) {
        final isSelected = selectedKey == cond.key;
        return InkWell(
          onTap: () => onSelect(cond.key),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cond.symbol,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  cond.label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Teeth grid ──────────────────────────────────────────────────────────────
class _TeethGrid extends StatelessWidget {
  final List<String> teeth;
  final Map<String, String> selections;
  final ValueChanged<String> onTap;

  const _TeethGrid({
    required this.teeth,
    required this.selections,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 8,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      childAspectRatio: 1,
      children: teeth.map((tooth) {
        final assigned = selections[tooth];
        final hasCondition =
            assigned != null && assigned.isNotEmpty;
        return InkWell(
          onTap: () => onTap(tooth),
          child: Container(
            decoration: BoxDecoration(
              color: hasCondition
                  ? AppColors.accentLight
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasCondition
                    ? AppColors.primary
                    : AppColors.border,
                width: hasCondition ? 2 : 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tooth,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (hasCondition)
                    Text(
                      assigned,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}