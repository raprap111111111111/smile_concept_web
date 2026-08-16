import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/doctor_repository.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import '/presentation/pages/doctors/widgets/doctor_form_dialog.dart';
import '/presentation/widgets/shared/hold_to_delete_dialog.dart';
import 'widgets/doctor_branches_section.dart';
import 'widgets/doctor_detail_header.dart';
import 'widgets/doctor_info_section.dart';
import 'widgets/doctor_schedules_section.dart';
import 'widgets/doctor_stats_section.dart';
import '/presentation/providers/doctor/doctor_list_provider.dart';

class DoctorDetailPage extends ConsumerWidget {
  final int doctorId;

  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorDetailProvider(doctorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Doctor Details', style: AppTextStyles.titleLarge),
        actions: doctorAsync.maybeWhen(
          data: (doctor) => [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              tooltip: 'Edit',
              onPressed: () => _openEditDialog(context, doctor),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
              onSelected: (val) {
                if (val == 'delete') _confirmDelete(context, ref, doctor);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          orElse: () => null,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: doctorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (doctor) => _buildContent(context, doctor),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // Content
  // ══════════════════════════════════════════════════════════
  Widget _buildContent(BuildContext context, Map<String, dynamic> doctor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (avatar + name + specialization)
          DoctorDetailHeader(doctor: doctor),
          const SizedBox(height: AppDimensions.paddingLarge),

          // Statistics
          DoctorStatsSection(doctor: doctor),
          const SizedBox(height: AppDimensions.paddingLarge),

          // Contact & Info
          DoctorInfoSection(doctor: doctor),
          const SizedBox(height: AppDimensions.paddingLarge),

          // Branches
          DoctorBranchesSection(doctor: doctor),
          const SizedBox(height: AppDimensions.paddingLarge),

          // Schedules
          DoctorSchedulesSection(doctor: doctor),
          const SizedBox(height: AppDimensions.paddingXL),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // Error State
  // ══════════════════════════════════════════════════════════
  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load doctor',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () => ref.invalidate(doctorDetailProvider(doctorId)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // Actions
  // ══════════════════════════════════════════════════════════
  void _openEditDialog(BuildContext context, Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (_) => DoctorFormDialog(doctor: doctor),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> doctor,
  ) async {
    final user = doctor['user'] as Map? ?? {};
    final name = user['name']?.toString() ?? 'this doctor';

    final confirmed = await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete Doctor',
      itemName: name,
      description:
          "You are about to delete Dr. $name from the system. "
          "This won't delete their user account, but the doctor profile "
          "and all associated schedules will be removed. "
          "This action cannot be undone.",
    );

    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(doctorRepositoryProvider).deleteDoctor(doctorId);
      ref.invalidate(doctorsProvider);

      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              "Dr. $name deleted successfully",
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Delete failed: $e',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ),
        );
      }
    }
  }
}