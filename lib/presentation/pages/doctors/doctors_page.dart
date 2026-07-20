// lib/presentation/pages/doctors/doctors_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/doctor_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/doctor_card.dart';
import 'widgets/doctor_form_dialog.dart';

class DoctorsPage extends ConsumerStatefulWidget {
  const DoctorsPage({super.key});

  @override
  ConsumerState<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends ConsumerState<DoctorsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsProvider);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onAdd: () => _openDialog()),
          const SizedBox(height: AppDimensions.paddingLarge),
          _SearchBar(
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          Expanded(
            child: doctorsAsync.when(
              data: (doctors) => _DoctorGrid(
                doctors: _filter(doctors),
                onEdit: (doc) => _openDialog(doctor: doc),
                onDelete: _confirmDelete,
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter ──
  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> doctors) {
    final query = _search.toLowerCase();
    return doctors.where((d) {
      final user = d['user'] as Map? ?? {};
      final name = (user['name'] ?? '').toString().toLowerCase();
      final spec = (d['specialization'] ?? '').toString().toLowerCase();
      return name.contains(query) || spec.contains(query);
    }).toList();
  }

  // ── Dialog opener ──
  void _openDialog({Map<String, dynamic>? doctor}) {
    showDialog(
      context: context,
      builder: (_) => DoctorFormDialog(doctor: doctor),
    );
  }

  // ── Delete confirmation ──
  void _confirmDelete(Map<String, dynamic> doctor) {
    final user = doctor['user'] as Map? ?? {};
    final name = user['name']?.toString() ?? 'this doctor';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        title: Text('Delete Doctor', style: AppTextStyles.titleMedium),
        content: Text(
          "Are you sure you want to delete '$name'? This won't delete their user account.",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                final repo = ref.read(doctorRepositoryProvider);
                await repo.deleteDoctor(doctor['id'] as int);
                ref.invalidate(doctorsProvider);
                if (!mounted) return;
                Navigator.pop(dialogContext);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.error,
                    content: Text('Error: $e'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusLarge,
                ),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctors', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Manage doctor profiles and specializations',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add Doctor'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name or specialization...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// ── Doctor Grid ───────────────────────────────────────────────
class _DoctorGrid extends StatelessWidget {
  final List<Map<String, dynamic>> doctors;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const _DoctorGrid({
    required this.doctors,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) return const _EmptyView();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.15,
      ),
      itemCount: doctors.length,
      itemBuilder: (context, i) => DoctorCard(
        doctor: doctors[i],
        onEdit: () => onEdit(doctors[i]),
        onDelete: () => onDelete(doctors[i]),
      ),
    );
  }
}

// ── Empty View ────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No doctors found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'Error: $message',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}