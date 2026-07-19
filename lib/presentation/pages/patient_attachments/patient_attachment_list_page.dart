// lib/presentation/pages/patient_attachments/patient_attachment_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/providers/patient_attachment/patient_attachment_provider.dart';
import '/presentation/route/route_names.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'widgets/attachment_card.dart';
import 'widgets/attachment_filter_bar.dart';

class PatientAttachmentListPage extends ConsumerStatefulWidget {
  final int? filterUserId;
  final String? patientName;

  const PatientAttachmentListPage({
    super.key,
    this.filterUserId,
    this.patientName,
  });

  @override
  ConsumerState<PatientAttachmentListPage> createState() =>
      _PatientAttachmentListPageState();
}

class _PatientAttachmentListPageState
    extends ConsumerState<PatientAttachmentListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(patientAttachmentProvider.notifier);

      // ✅ Apply filter if navigated from folder
      if (widget.filterUserId != null) {
        await notifier.setUserFilter(widget.filterUserId);
      } else {
        // Clear filter and reload
        await notifier.setUserFilter(null);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final state = ref.read(patientAttachmentProvider);

    if (state.isLoading) return;
    if (!state.hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(patientAttachmentProvider.notifier).loadMore();
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
    final state = ref.watch(patientAttachmentProvider);
    final isFiltered = widget.filterUserId != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(context, isFiltered),
          const AttachmentFilterBar(),
          Expanded(child: _buildList(state)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.pushNamed(RouteNames.attachmentUpload),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }

  Widget _buildList(PatientAttachmentState state) {
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
      onRefresh: () => ref
          .read(patientAttachmentProvider.notifier)
          .fetchAll(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount:
            state.attachments.length + (state.hasMore ? 1 : 0),
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

  Widget _buildHeader(BuildContext context, bool isFiltered) {
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
              // ✅ Back button if filtered
              if (isFiltered) ...[
                IconButton(
                  onPressed: () =>
                      context.goNamed(RouteNames.patientFolders),
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadius),
                ),
                child: Icon(
                  isFiltered
                      ? Icons.folder_shared
                      : Icons.attach_file,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFiltered && widget.patientName != null
                          ? "${widget.patientName}'s Files"
                          : 'Patient Attachments',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFiltered
                          ? 'All files uploaded for this patient'
                          : 'X-rays, photos, documents & AI scan results',
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
                .read(patientAttachmentProvider.notifier)
                .setSearch(v.isEmpty ? null : v),
            decoration: InputDecoration(
              hintText: 'Search attachments...',
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(patientAttachmentProvider.notifier)
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
                borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
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
          Text('No attachments found',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text('Upload X-rays, photos, or documents',
              style: AppTextStyles.bodySmall),
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
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            TextButton(
              onPressed: () => ref
                  .read(patientAttachmentProvider.notifier)
                  .fetchAll(refresh: true),
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
        title:
            Text('Delete Attachment', style: AppTextStyles.titleMedium),
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
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(patientAttachmentProvider.notifier)
                  .delete(attachment.id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}