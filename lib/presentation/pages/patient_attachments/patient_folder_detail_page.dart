// lib/presentation/pages/patient_attachments/patient_folder_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/permissions/app_permissions.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/providers/auth/auth_provider.dart';
import '/presentation/providers/patient_folder/patient_folder_provider.dart';
import '/presentation/providers/patient_attachment/patient_attachment_provider.dart';
import '/presentation/route/route_names.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'widgets/attachment_card.dart';

class PatientFolderDetailPage extends ConsumerStatefulWidget {
  final int patientId;
  final String? patientName;

  const PatientFolderDetailPage({
    super.key,
    required this.patientId,
    this.patientName,
  });

  @override
  ConsumerState<PatientFolderDetailPage> createState() =>
      _PatientFolderDetailPageState();
}

class _PatientFolderDetailPageState
    extends ConsumerState<PatientFolderDetailPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ Open the folder — loads the patient's attachments
      ref.read(patientFolderProvider.notifier).openFolder(
            patientId: widget.patientId,
            patientName: widget.patientName,
          );
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final state = ref.read(patientFolderProvider);
    if (state.isLoading || !state.hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(patientFolderProvider.notifier).loadMore();
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
    final state = ref.watch(patientFolderProvider);
    final auth = ref.watch(authStateProvider);
    final canViewAny = auth.hasPermission(Perm.attachmentViewAny);
    final canUpload = auth.hasPermission(Perm.attachmentUpload);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(context, state),
          _buildScopeIndicator(canViewAny, state),
          _buildFilterBar(state),
          Expanded(child: _buildList(state)),
        ],
      ),
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.pushNamed(RouteNames.attachmentUpload),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, PatientFolderState state) {
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
              IconButton(
                onPressed: () => context.goNamed(RouteNames.patientFolders),
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
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
                    Text(
                      state.patientName != null
                          ? "${state.patientName}'s Folder"
                          : (widget.patientName ?? 'Patient Folder'),
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.patientEmail ?? 'Files uploaded for this patient',
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
                .read(patientFolderProvider.notifier)
                .setSearch(v.isEmpty ? null : v),
            decoration: InputDecoration(
              hintText: 'Search in this folder...',
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(patientFolderProvider.notifier)
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

  Widget _buildScopeIndicator(bool canViewAny, PatientFolderState state) {
    final label = canViewAny
        ? 'All uploads for this patient'
        : 'Your uploads for this patient';
    final icon = canViewAny ? Icons.groups_outlined : Icons.person_outline;
    final color = canViewAny ? AppColors.info : AppColors.primary;

    return Container(
      color: color.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${state.total} file(s)',
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(PatientFolderState state) {
    final categories = [
      ('All', null),
      ('X-Rays', 'xray'),
      ('Photos', 'photo'),
      ('Consent', 'consent_form'),
      ('Lab Reports', 'lab_report'),
      ('Prescriptions', 'prescription'),
      ('Other', 'other'),
    ];

    return Container(
      height: 50,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = state.categoryFilter == cat.$2;

          return ChoiceChip(
            label: Text(cat.$1),
            selected: isSelected,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => ref
                .read(patientFolderProvider.notifier)
                .setCategoryFilter(cat.$2),
          );
        },
      ),
    );
  }

  Widget _buildList(PatientFolderState state) {
    if (state.isLoading && state.attachments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.attachments.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.attachments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(patientFolderProvider.notifier).fetch(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: state.attachments.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDimensions.paddingSmall),
        itemBuilder: (context, index) {
          if (index >= state.attachments.length) {
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

          final attachment = state.attachments[index];
          return AttachmentCard(
            attachment: attachment,
            onTap: () => _openDetail(attachment),
            onDelete: () => _confirmDelete(attachment),
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
            child: const Icon(Icons.folder_open_outlined,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text('No files in this folder', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Upload files for this patient to see them here',
            style: AppTextStyles.bodySmall,
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
            Text('Something went wrong', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              error,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            TextButton(
              onPressed: () => ref
                  .read(patientFolderProvider.notifier)
                  .fetch(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(PatientAttachment attachment) {
    context.pushNamed(
      RouteNames.patientAttachmentDetail,
      pathParameters: {'id': attachment.id.toString()},
      extra: attachment,
    );
  }

  void _confirmDelete(PatientAttachment attachment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusLarge),
        ),
        title: Text('Delete Attachment', style: AppTextStyles.titleMedium),
        content: Text(
          'Are you sure you want to delete "${attachment.fileName}"?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(patientAttachmentProvider.notifier)
                  .delete(attachment.id);
              // Reload the folder
              await ref
                  .read(patientFolderProvider.notifier)
                  .fetch(refresh: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}