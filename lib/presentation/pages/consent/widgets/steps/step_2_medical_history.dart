import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smile_concept_web/data/models/consent/consent_form_data.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/theme/app_dimensions.dart';
import 'package:smile_concept_web/presentation/theme/app_text_styles.dart';
import 'package:smile_concept_web/presentation/pages/consent/widgets/yes_no_question.dart';
import 'package:smile_concept_web/presentation/pages/consent/widgets/section_title.dart';
import 'package:smile_concept_web/presentation/providers/consent/sign_consent_form_provider.dart';

class Step2MedicalHistory extends ConsumerStatefulWidget {
  const Step2MedicalHistory({super.key});

  @override
  ConsumerState<Step2MedicalHistory> createState() =>
      _Step2MedicalHistoryState();
}

class _Step2MedicalHistoryState extends ConsumerState<Step2MedicalHistory> {
  late final TextEditingController _treatmentCtrl;
  late final TextEditingController _illnessCtrl;
  late final TextEditingController _hospitalizationCtrl;
  late final TextEditingController _medicationsCtrl;
  late final TextEditingController _bleedingTimeCtrl;
  late final TextEditingController _bloodTypeCtrl;
  late final TextEditingController _bloodPressureCtrl;
  late final TextEditingController _otherAllergiesCtrl;
  late final TextEditingController _otherConditionsCtrl;

  // ✅ Shared light theme input style (matches Appointments form)
  static InputDecoration _inputDeco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final s = ref.read(consentFormProvider);
    _treatmentCtrl = TextEditingController(text: s.treatmentCondition);
    _illnessCtrl = TextEditingController(text: s.illnessDetails);
    _hospitalizationCtrl = TextEditingController(text: s.hospitalizationDetails);
    _medicationsCtrl = TextEditingController(text: s.medications);
    _bleedingTimeCtrl = TextEditingController(text: s.bleedingTime);
    _bloodTypeCtrl = TextEditingController(text: s.bloodType);
    _bloodPressureCtrl = TextEditingController(text: s.bloodPressure);
    _otherAllergiesCtrl = TextEditingController(text: s.otherAllergies);
    _otherConditionsCtrl = TextEditingController(text: s.otherConditions);
  }

  @override
  void dispose() {
    for (final ctrl in [
      _treatmentCtrl,
      _illnessCtrl,
      _hospitalizationCtrl,
      _medicationsCtrl,
      _bleedingTimeCtrl,
      _bloodTypeCtrl,
      _bloodPressureCtrl,
      _otherAllergiesCtrl,
      _otherConditionsCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _pushText(String field, String value) {
    if (!mounted) return;
    ref.read(consentFormProvider.notifier).setMedicalText(field, value);
  }

  void _pushBool(String field, bool value) {
    if (!mounted) return;
    ref.read(consentFormProvider.notifier).setMedicalBool(field, value);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(consentFormProvider);
    final notifier = ref.read(consentFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Medical History Questions',
            icon: Icons.medical_information_outlined,
          ),
          const SizedBox(height: 8),

          YesNoQuestion(
            question: '1. Are you in good health?',
            value: s.inGoodHealth,
            onChanged: (v) => _pushBool('inGoodHealth', v),
          ),
          YesNoQuestion(
            question: '2. Are you under medical treatment now?',
            value: s.underMedicalTreatment,
            onChanged: (v) => _pushBool('underMedicalTreatment', v),
          ),
          if (s.underMedicalTreatment == true)
            _conditionalField(
              'If so, what is being treated?',
              _treatmentCtrl,
              'treatmentCondition',
            ),

          YesNoQuestion(
            question: '3. Have you had serious illness or surgery?',
            value: s.hadSeriousIllness,
            onChanged: (v) => _pushBool('hadSeriousIllness', v),
          ),
          if (s.hadSeriousIllness == true)
            _conditionalField(
              'If so, what illness/operation?',
              _illnessCtrl,
              'illnessDetails',
            ),

          YesNoQuestion(
            question: '4. Have you ever been hospitalized?',
            value: s.wasHospitalized,
            onChanged: (v) => _pushBool('wasHospitalized', v),
          ),
          if (s.wasHospitalized == true)
            _conditionalField(
              'If so, when and why?',
              _hospitalizationCtrl,
              'hospitalizationDetails',
            ),

          YesNoQuestion(
            question: '5. Taking any prescription/non-prescription meds?',
            value: s.takesMedications,
            onChanged: (v) => _pushBool('takesMedications', v),
          ),
          if (s.takesMedications == true)
            _conditionalField(
              'If so, please specify:',
              _medicationsCtrl,
              'medications',
            ),

          YesNoQuestion(
            question: '6. Do you use tobacco products?',
            value: s.usesTobacco,
            onChanged: (v) => _pushBool('usesTobacco', v),
          ),

          YesNoQuestion(
            question: '7. Do you use alcohol, cocaine or other drugs?',
            value: s.usesAlcoholDrugs,
            onChanged: (v) => _pushBool('usesAlcoholDrugs', v),
          ),

          YesNoQuestion(
            question: '8. Are you allergic to any of the following?',
            value: s.hasAllergies,
            onChanged: (v) => _pushBool('hasAllergies', v),
          ),
          if (s.hasAllergies == true) ...[
            const SizedBox(height: 8),
            _AllergiesGrid(
              selected: s.selectedAllergies,
              onToggle: notifier.toggleAllergy,
            ),
            const SizedBox(height: 8),
            _conditionalField(
              'Other allergies:',
              _otherAllergiesCtrl,
              'otherAllergies',
            ),
          ],

          const SizedBox(height: 12),
          TextField(
            controller: _bleedingTimeCtrl,
            onChanged: (v) => _pushText('bleedingTime', v),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: _inputDeco('9. Bleeding Time'),
          ),
          const SizedBox(height: 8),

          YesNoQuestion(
            question: '10. For women: pregnant / nursing / birth control?',
            value: s.isPregnant,
            onChanged: (v) => _pushBool('isPregnant', v),
          ),

          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _bloodTypeCtrl,
                onChanged: (v) => _pushText('bloodType', v),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: _inputDeco('11. Blood Type'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _bloodPressureCtrl,
                onChanged: (v) => _pushText('bloodPressure', v),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: _inputDeco('12. Blood Pressure'),
              ),
            ),
          ]),

          const SizedBox(height: 20),
          const SectionTitle(
            title: '13. Do you have or have had any of the following?',
            icon: Icons.check_box_outlined,
          ),
          const SizedBox(height: 8),
          _ConditionsGrid(
            selected: s.selectedConditions,
            onToggle: notifier.toggleCondition,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _otherConditionsCtrl,
            onChanged: (v) => _pushText('otherConditions', v),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: _inputDeco('Other conditions'),
          ),
        ],
      ),
    );
  }

  Widget _conditionalField(
    String label,
    TextEditingController ctrl,
    String field,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
      child: TextField(
        controller: ctrl,
        onChanged: (v) => _pushText(field, v),
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: _inputDeco(label),
      ),
    );
  }
}

class _ConditionsGrid extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _ConditionsGrid({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: kMedicalConditions
          .map(
            (c) => SizedBox(
              width: 220,
              child: _CheckRow(
                label: c['label']!,
                checked: selected.contains(c['key']),
                onToggle: () => onToggle(c['key']!),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AllergiesGrid extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _AllergiesGrid({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: kAllergyTypes
            .map(
              (a) => SizedBox(
                width: 240,
                child: _CheckRow(
                  label: a['label']!,
                  checked: selected.contains(a['key']),
                  onToggle: () => onToggle(a['key']!),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onToggle;

  const _CheckRow({
    required this.label,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: checked ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}