// lib/presentation/pages/patient_attachments/patient_folders_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '/presentation/providers/patient_attachment/patients_with_attachments_provider.dart';
import '/presentation/route/route_names.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'widgets/patient_folder_card.dart';

class PatientFoldersPage extends ConsumerStatefulWidget {
  const PatientFoldersPage({super.key});

  @override
  ConsumerState<PatientFoldersPage> createState() =>
      _PatientFoldersPageState();
}

class _PatientFoldersPageState extends ConsumerState<PatientFoldersPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final state = ref.read(patientsWithAttachmentsProvider);
    if (state.isLoading || !state.hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(patientsWithAttachmentsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientsWithAttachmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(state),
          // ✅ NEW: Quick action buttons
          _buildQuickActions(context, state),
          Expanded(child: _buildContent(state)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.attachmentUpload),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }

  Widget _buildHeader(PatientsWithAttachmentsState state) {
    final totalPatients = state.patients.length;
    final totalPending = state.patients
        .fold<int>(0, (sum, p) => sum + p.pendingScans);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        AppDimensions.paddingMedium,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                child: const Icon(Icons.folder_shared,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Files',
                        style: AppTextStyles.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      '$totalPatients patients${totalPending > 0 ? " • $totalPending pending AI scans" : ""}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          TextField(
            controller: _searchController,
            onChanged: (v) => ref
                .read(patientsWithAttachmentsProvider.notifier)
                .setSearch(v.isEmpty ? null : v),
            decoration: InputDecoration(
              hintText: 'Search patient by name or email...',
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(patientsWithAttachmentsProvider.notifier)
                            .setSearch(null);
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ✅ NEW: Quick Action Buttons Row
  // ═══════════════════════════════════════════════════════
  Widget _buildQuickActions(
      BuildContext context, PatientsWithAttachmentsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.folder_open,
              label: 'All Files',
              color: AppColors.primary,
              onTap: () =>
                  context.pushNamed(RouteNames.patientAttachments),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.medical_information,
              label: 'All X-rays',
              color: AppColors.info,
              onTap: () {
                // Navigate to all attachments with X-ray filter
                context.pushNamed(RouteNames.patientAttachments);
                // Note: You may want to auto-apply X-ray filter here
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.smart_toy,
              label: 'AI Scans',
              color: AppColors.success,
              onTap: () {
                context.pushNamed(RouteNames.patientAttachments);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PatientsWithAttachmentsState state) {
    if (state.isLoading && state.patients.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.patients.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.patients.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref
          .read(patientsWithAttachmentsProvider.notifier)
          .fetch(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: state.patients.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDimensions.paddingSmall),
        itemBuilder: (context, index) {
          if (index >= state.patients.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.paddingMedium),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final patient = state.patients[index];
          return PatientFolderCard(
            patient: patient,
            onTap: () => context.pushNamed(
              RouteNames.patientAttachmentsByPatient,
              pathParameters: {'userId': patient.id.toString()},
              extra: patient,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_off_outlined,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text('No patient files yet',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text('Upload attachments to see them here',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: AppDimensions.paddingMedium),
          ElevatedButton.icon(
            onPressed: () =>
                context.pushNamed(RouteNames.attachmentUpload),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload First Attachment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text('Something went wrong',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              error,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            TextButton(
              onPressed: () => ref
                  .read(patientsWithAttachmentsProvider.notifier)
                  .fetch(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// QUICK ACTION BUTTON WIDGET
// ═══════════════════════════════════════════════════════════
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}