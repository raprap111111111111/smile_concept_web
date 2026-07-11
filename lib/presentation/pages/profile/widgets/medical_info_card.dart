// lib/presentation/pages/profile/widgets/medical_info_card.dart
import 'package:flutter/material.dart';

import '../../../../data/models/profile/patient_profile_model.dart';
import 'info_card.dart';

class MedicalInfoCard extends StatelessWidget {
  final PatientProfileModel patientProfile;
  const MedicalInfoCard({super.key, required this.patientProfile});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Medical Information',
      icon: Icons.medical_information_outlined,
      iconColor: Colors.redAccent,
      trailing: !patientProfile.isMedicallyComplete
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.orange.withValues(alpha: 0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 12,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'INCOMPLETE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          : null,
      children: [
        _MedicalRow(
          icon: Icons.bloodtype_outlined,
          label: 'Blood Type',
          value: patientProfile.bloodType ?? 'Not provided',
          isEmpty: patientProfile.bloodType == null,
        ),
        _MedicalRow(
          icon: Icons.warning_amber_outlined,
          label: 'Allergies',
          value: patientProfile.allergies ?? 'None declared',
          isEmpty: patientProfile.allergies == null,
        ),
        _MedicalRow(
          icon: Icons.history_outlined,
          label: 'Medical History',
          value: patientProfile.medicalHistory ?? 'None declared',
          isEmpty: patientProfile.medicalHistory == null,
        ),
        _MedicalRow(
          icon: Icons.person_outline,
          label: 'Emergency Contact',
          value: patientProfile.emergencyContactName ?? 'Not provided',
          isEmpty: patientProfile.emergencyContactName == null,
        ),
        _MedicalRow(
          icon: Icons.phone_outlined,
          label: 'Emergency Phone',
          value: patientProfile.emergencyContactPhone ?? 'Not provided',
          isEmpty: patientProfile.emergencyContactPhone == null,
          isLast: !patientProfile.hasMedicalAlerts,
        ),
        if (patientProfile.hasMedicalAlerts) ...[
          const SizedBox(height: 20),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'MEDICAL ALERTS',
                style: TextStyle(
                  color: Colors.redAccent.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: patientProfile.activeAlerts
                .map((alert) => _AlertChip(label: alert))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────
class _MedicalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;
  final bool isLast;

  const _MedicalRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.redAccent.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: isEmpty
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                    height: 1.4,
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

class _AlertChip extends StatelessWidget {
  final String label;
  const _AlertChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}