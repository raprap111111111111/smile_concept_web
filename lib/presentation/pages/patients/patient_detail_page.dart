// lib/presentation/pages/patients/patient_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/patient/patient_list_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';

class PatientDetailPage extends ConsumerWidget {
  final int patientId;

  const PatientDetailPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load patient: $e',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.patients),
                child: const Text('Back to Patients'),
              ),
            ],
          ),
        ),
        data: (patient) {
          final profile = patient.patientProfile;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───────────────────────────────
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.goNamed(RouteNames.patients),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.goNamed(
                        RouteNames.patientEdit,
                        pathParameters: {'id': '$patientId'},
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ─── Personal Information ─────────────────
                _sectionCard(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  children: [
                    _infoRow('Full Name', patient.name),
                    _infoRow('Email', patient.email),
                    _infoRow('Phone', patient.phone ?? '—'),
                    _infoRow(
                        'Branch ID', patient.branchId?.toString() ?? '—'),
                    _infoRow('Created', patient.createdAt ?? '—'),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Medical Information ──────────────────
                _sectionCard(
                  title: 'Medical Information',
                  icon: Icons.medical_information_outlined,
                  children: [
                    _infoRow('Blood Type', profile.bloodType ?? '—'),
                    _infoRow('Allergies', profile.allergies ?? 'None'),
                    _infoRow(
                        'Medical History', profile.medicalHistory ?? 'None'),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Emergency Contact ────────────────────
                _sectionCard(
                  title: 'Emergency Contact',
                  icon: Icons.emergency_outlined,
                  children: [
                    _infoRow('Name', profile.emergencyContactName ?? '—'),
                    _infoRow('Phone', profile.emergencyContactPhone ?? '—'),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Special Conditions ───────────────────
                _sectionCard(
                  title: 'Special Conditions',
                  icon: Icons.warning_amber_outlined,
                  children: [
                    _boolRow('Requires Epinephrine-free Anesthesia',
                        profile.requiresEpinephrineFreeAnesthesia),
                    _boolRow('Has Cardiac Conditions',
                        profile.hasCardiacConditions),
                    _boolRow('Is Pregnant', profile.isPregnant),
                    _boolRow('Has Bleeding Disorders',
                        profile.hasBleedingDisorders),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boolRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: value
                  ? Colors.red.withValues(alpha: 0.15)
                  : Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value ? 'YES' : 'NO',
              style: TextStyle(
                color: value ? Colors.redAccent : Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}