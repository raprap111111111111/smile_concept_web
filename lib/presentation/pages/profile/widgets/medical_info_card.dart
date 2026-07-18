// lib/presentation/pages/profile/widgets/medical_info_card.dart
import 'package:flutter/material.dart';

import '../../../../data/models/profile/patient_profile_model.dart';
import 'info_card.dart';
import 'profile_theme.dart';

class MedicalInfoCard extends StatelessWidget {
  final PatientProfileModel patientProfile;
  const MedicalInfoCard({super.key, required this.patientProfile});

  @override
  Widget build(BuildContext context) {
    final hasAlerts = patientProfile.hasMedicalAlerts;

    return InfoCard(
      title: 'Medical information',
      icon: Icons.medical_information_outlined,
      iconColor: ProfileTokens.brand,
      trailing: patientProfile.isMedicallyComplete
          ? null
          : const StatusPill(
              label: 'Incomplete',
              foreground: ProfileTokens.warning,
              background: ProfileTokens.warningSubtle,
              icon: Icons.info_outline,
            ),
      children: [
        InfoRow(
          icon: Icons.bloodtype_outlined,
          label: 'Blood type',
          value: patientProfile.bloodType ?? 'Not provided',
          isEmpty: patientProfile.bloodType == null,
        ),
        InfoRow(
          icon: Icons.warning_amber_outlined,
          label: 'Allergies',
          value: patientProfile.allergies ?? 'None declared',
          isEmpty: patientProfile.allergies == null,
        ),
        InfoRow(
          icon: Icons.history_outlined,
          label: 'Medical history',
          value: patientProfile.medicalHistory ?? 'None declared',
          isEmpty: patientProfile.medicalHistory == null,
        ),
        InfoRow(
          icon: Icons.contact_emergency_outlined,
          label: 'Emergency contact',
          value: patientProfile.emergencyContactName ?? 'Not provided',
          isEmpty: patientProfile.emergencyContactName == null,
        ),
        InfoRow(
          icon: Icons.phone_outlined,
          label: 'Emergency phone',
          value: patientProfile.emergencyContactPhone ?? 'Not provided',
          isEmpty: patientProfile.emergencyContactPhone == null,
          isLast: true,
        ),

        // ─── Alerts ──────────────────────────────────────────────────────
        // Clinically the most important thing on the page, so it gets its
        // own block below the rows rather than another quiet label/value.
        if (hasAlerts) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ProfileTokens.dangerSubtle,
              borderRadius: BorderRadius.circular(ProfileTokens.radiusSm),
              border: Border.all(
                color: ProfileTokens.danger.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: ProfileTokens.danger,
                      size: 17,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Medical alerts',
                      style: TextStyle(
                        color: ProfileTokens.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: patientProfile.activeAlerts
                      .map(
                        (alert) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: ProfileTokens.card,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  ProfileTokens.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            alert,
                            style: const TextStyle(
                              color: ProfileTokens.danger,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
