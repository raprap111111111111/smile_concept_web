// lib/presentation/pages/patients/patient_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/patient/patient_list_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/patient_bool_row.dart';
import 'widgets/patient_info_row.dart';
import 'widgets/patient_page_header.dart';
import 'widgets/patient_section_card.dart';

class PatientDetailPage extends ConsumerWidget {
  final int patientId;
  const PatientDetailPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));
    final canUpdate =
        ref.watch(permissionServiceProvider).can(Perm.patientUpdate);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onBack: () => context.goNamed(RouteNames.patients),
        ),
        data: (patient) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PatientPageHeader(
                title: patient.name,
                onBack: () => context.goNamed(RouteNames.patients),
                trailing: canUpdate
                    ? FilledButton.icon(
                        onPressed: () => context.goNamed(
                          RouteNames.patientEdit,
                          pathParameters: {'id': '$patientId'},
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppDimensions.paddingXL),

              PatientSectionCard(
                title: 'Personal Information',
                icon: Icons.person_outline,
                children: [
                  PatientInfoRow(label: 'Full Name', value: patient.name),
                  PatientInfoRow(label: 'Email', value: patient.email),
                  PatientInfoRow(
                      label: 'Phone', value: patient.phone ?? '—'),
                  PatientInfoRow(
                      label: 'Branch ID',
                      value: patient.branchId?.toString() ?? '—'),
                  PatientInfoRow(
                      label: 'Created', value: patient.createdAt ?? '—'),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              PatientSectionCard(
                title: 'Medical Information',
                icon: Icons.medical_information_outlined,
                children: [
                  PatientInfoRow(
                      label: 'Blood Type',
                      value: patient.patientProfile.bloodType ?? '—'),
                  PatientInfoRow(
                      label: 'Allergies',
                      value: patient.patientProfile.allergies ?? 'None'),
                  PatientInfoRow(
                      label: 'Medical History',
                      value:
                          patient.patientProfile.medicalHistory ?? 'None'),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              PatientSectionCard(
                title: 'Emergency Contact',
                icon: Icons.emergency_outlined,
                children: [
                  PatientInfoRow(
                      label: 'Name',
                      value:
                          patient.patientProfile.emergencyContactName ?? '—'),
                  PatientInfoRow(
                      label: 'Phone',
                      value:
                          patient.patientProfile.emergencyContactPhone ?? '—'),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              PatientSectionCard(
                title: 'Special Conditions',
                icon: Icons.warning_amber_outlined,
                children: [
                  PatientBoolRow(
                    label: 'Requires Epinephrine-free Anesthesia',
                    value: patient.patientProfile
                        .requiresEpinephrineFreeAnesthesia,
                  ),
                  PatientBoolRow(
                    label: 'Has Cardiac Conditions',
                    value: patient.patientProfile.hasCardiacConditions,
                  ),
                  PatientBoolRow(
                    label: 'Is Pregnant',
                    value: patient.patientProfile.isPregnant,
                  ),
                  PatientBoolRow(
                    label: 'Has Bleeding Disorders',
                    value: patient.patientProfile.hasBleedingDisorders,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorView({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load patient: $message',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onBack,
            child: const Text('Back to Patients'),
          ),
        ],
      ),
    );
  }
}