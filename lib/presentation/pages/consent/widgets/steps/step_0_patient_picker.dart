import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smile_concept_web/data/models/consent/consent_form_data.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/theme/app_dimensions.dart';
import 'package:smile_concept_web/presentation/theme/app_text_styles.dart';
import 'package:smile_concept_web/presentation/pages/consent/widgets/choice_card.dart';
import 'package:smile_concept_web/presentation/providers/consent/sign_consent_form_provider.dart';

// ─── Replace LoadingWidget with a simple inline fallback ────────────────────
// since LoadingWidget is not a class in your project — use CircularProgressIndicator

class Step0PatientPicker extends ConsumerStatefulWidget {
  const Step0PatientPicker({super.key});

  @override
  ConsumerState<Step0PatientPicker> createState() => _Step0PatientPickerState();
}

class _Step0PatientPickerState extends ConsumerState<Step0PatientPicker> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(consentFormProvider);
    final notifier = ref.read(consentFormProvider.notifier);
    final patientsAsync = ref.watch(dialogPatientsProvider(_searchCtrl.text));

    return Column(
      children: [
        // ── Search ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search patient by name…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // ── Patient List ─────────────────────────────────────────────────
        Expanded(
          child: patientsAsync.when(
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading patients…'),
                ],
              ),
            ),
            error: (e, _) =>
                Center(child: Text('Failed to load patients: $e')),
            data: (patients) {
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
                  final isSelected =
                      formState.selectedPatient?.id == p.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : AppColors.accentLight,
                      child: Text(
                        p.name.isNotEmpty
                            ? p.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textOnPrimary
                              : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: Text(p.email),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () => notifier.selectPatient(p),
                  );
                },
              );
            },
          ),
        ),

        // ── Relation Picker ──────────────────────────────────────────────
        if (formState.selectedPatient != null) ...[
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who is being signed for?',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceCard(
                        title: 'Self / Patient',
                        subtitle: 'Patient signs for themselves',
                        selected: formState.patientRelation ==
                            PatientRelation.self,
                        icon: Icons.person,
                        onTap: () => notifier
                            .setPatientRelation(PatientRelation.self),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceCard(
                        title: 'Guardian / Minor',
                        subtitle: 'Guardian signs on behalf',
                        selected: formState.patientRelation ==
                            PatientRelation.minorDependent,
                        icon: Icons.people,
                        onTap: () => notifier.setPatientRelation(
                            PatientRelation.minorDependent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}