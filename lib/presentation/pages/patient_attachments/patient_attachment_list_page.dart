// lib/presentation/pages/patient_attachments/patient_attachment_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/permissions/app_permissions.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/providers/auth/auth_provider.dart';
import '/presentation/providers/patient_attachment/patient_attachment_provider.dart';
import '/presentation/route/route_names.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import '../../widgets/shared/hold_to_delete_dialog.dart';
import '../../widgets/shared/search_bar_onclick.dart';
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
      debugPrint('🚀 PatientAttachmentListPage initState');
      debugPrint('   filterUserId: ${widget.filterUserId}');
      debugPrint('   patientName: ${widget.patientName}');

      await notifier.clearFilters();
      if (widget.filterUserId != null) {
        await notifier.setUserFilter(widget.filterUserId);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final state = ref.read(patientAttachmentProvider);
    if (state.isLoading || !state.hasMore) return;

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

  // ── Search ──
  void _onSearch(String value) {
    ref
        .read(patientAttachmentProvider.notifier)
        .setSearch(value.isEmpty ? null : value);
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(patientAttachmentProvider.notifier).setSearch(null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientAttachmentProvider);
    final auth = ref.watch(authStateProvider);
    final isFiltered = widget.filterUserId != null;
    final canViewAny = auth.hasPermission(Perm.attachmentViewAny);
    final canUpload = auth.hasPermission(Perm.attachmentUpload);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _PageHeader(
            isFiltered: isFiltered,
            patientName: widget.patientName,
            searchController: _searchController,
            onBack: () => context.goNamed(RouteNames.patientFolders),
            onSearch: _onSearch,
            onClearSearch: _onClearSearch,
          ),
          _ScopeIndicator(
            canViewAny: canViewAny,
            isFiltered: isFiltered,
            count: state.attachments.length,
          ),
          const AttachmentFilterBar(),
          Expanded(child: _buildList(state, canViewAny)),
        ],
      ),
      floatingActionButton: canUpload ? _buildUploadFAB() : null,
    );
  }

  Widget _buildUploadFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.pushNamed(RouteNames.attachmentUpload),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      icon: const Icon(Icons.upload_file_rounded),
      label: Text(
        'Upload',
        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildList(PatientAttachmentState state, bool canViewAny) {
    if (state.isLoading && state.attachments.isEmpty) {
      return const _LoadingView();
    }

    if (state.error != null && state.attachments.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref
            .read(patientAttachmentProvider.notifier)
            .fetchAll(refresh: true),
      );
    }

    if (state.attachments.isEmpty) {
      return _EmptyState(canViewAny: canViewAny);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.background,
      onRefresh: () =>
          ref.read(patientAttachmentProvider.notifier).fetchAll(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: state.attachments.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDimensions.paddingSmall),
        itemBuilder: (context, index) {
          if (index >= state.attachments.length) {
            return const _LoadMoreIndicator();
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

  void _openDetail(PatientAttachment attachment) {
    context.pushNamed(
      RouteNames.patientAttachmentDetail,
      pathParameters: {'id': attachment.id.toString()},
      extra: attachment,
    );
  }

  Future<void> _confirmDelete(PatientAttachment attachment) async {
    final confirmed = await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete Attachment',
      itemName: attachment.fileName,
      description: 'You are about to delete "${attachment.fileName}". '
          'The file will be permanently removed from patient records '
          'and cannot be recovered. This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    try {
      await ref.read(patientAttachmentProvider.notifier).delete(attachment.id);
      if (!mounted) return;
      _showSnack('"${attachment.fileName}" deleted', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to delete: $e', AppColors.error);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isFiltered,
    required this.patientName,
    required this.searchController,
    required this.onBack,
    required this.onSearch,
    required this.onClearSearch,
  });

  final bool isFiltered;
  final String? patientName;
  final TextEditingController searchController;
  final VoidCallback onBack;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final title = isFiltered && patientName != null
        ? "$patientName's Files"
        : 'Patient Attachments';
    final subtitle = isFiltered
        ? 'All files uploaded for this patient'
        : 'X-rays, photos, documents & AI scan results';

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
          // ── Title Row ──
          Row(
            children: [
              if (isFiltered) ...[
                _BackButton(onPressed: onBack),
                const SizedBox(width: AppDimensions.paddingSmall),
              ],
              Container(
                width: AppDimensions.iconBadgeSize,
                height: AppDimensions.iconBadgeSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  isFiltered
                      ? Icons.folder_shared_rounded
                      : Icons.attach_file_rounded,
                  color: AppColors.primary,
                  size: AppDimensions.iconSize,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleLarge),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),

          // ── Search Bar (onClick) ──
          SearchBarOnClick(
            controller: searchController,
            hintText: 'Search attachments...',
            onChanged: onSearch,
            onClear: onClearSearch,
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: AppDimensions.iconSizeSmall,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Scope Indicator ──────────────────────────────────────────────────────────

class _ScopeIndicator extends StatelessWidget {
  const _ScopeIndicator({
    required this.canViewAny,
    required this.isFiltered,
    required this.count,
  });

  final bool canViewAny;
  final bool isFiltered;
  final int count;

  @override
  Widget build(BuildContext context) {
    final String label;
    final IconData icon;
    final Color color;

    if (canViewAny) {
      label = isFiltered
          ? 'All uploads for this patient'
          : 'All uploads (any user)';
      icon = Icons.groups_rounded;
      color = AppColors.info;
    } else {
      label =
          isFiltered ? 'Your uploads for this patient' : 'Your uploads only';
      icon = Icons.person_outline_rounded;
      color = AppColors.primary;
    }

    return Container(
      color: color.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: AppDimensions.paddingXS,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppDimensions.iconSizeSmall, color: color),
          const SizedBox(width: AppDimensions.paddingXS),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: color),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingXS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(
              '$count file(s)',
              style: AppTextStyles.labelSmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── State Views ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Loading attachments...',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text(
              'Loading more...',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canViewAny});

  final bool canViewAny;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.06),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
                border: Border.all(
                  color: AppColors.primaryWithOpacity(0.12),
                ),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 40,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text(
              canViewAny
                  ? 'No attachments found'
                  : "You haven't uploaded any files",
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              canViewAny
                  ? 'Upload X-rays, photos, or documents to see them here'
                  : 'Files you upload will appear here',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text('Something went wrong', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              message,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                size: AppDimensions.iconSizeSmall,
              ),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}