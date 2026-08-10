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
import '../../widgets/shared/hold_to_delete_dialog.dart';
import '../../widgets/shared/search_bar_onclick.dart';
import 'widgets/attachment_card.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

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

  // ── Search ──
  void _onSearch(String value) {
    ref
        .read(patientFolderProvider.notifier)
        .setSearch(value.isEmpty ? null : value);
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(patientFolderProvider.notifier).setSearch(null);
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
          _FolderHeader(
            state: state,
            fallbackName: widget.patientName,
            searchController: _searchController,
            onSearch: _onSearch,
            onClearSearch: _onClearSearch,
            onBack: () => context.goNamed(RouteNames.patientFolders),
          ),
          _ScopeIndicator(canViewAny: canViewAny, total: state.total),
          _FilterBar(
            selected: state.categoryFilter,
            onSelected: (v) =>
                ref.read(patientFolderProvider.notifier).setCategoryFilter(v),
          ),
          Expanded(child: _buildList(state)),
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

  Widget _buildList(PatientFolderState state) {
    if (state.isLoading && state.attachments.isEmpty) {
      return const _LoadingView();
    }

    if (state.error != null && state.attachments.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(patientFolderProvider.notifier).fetch(refresh: true),
      );
    }

    if (state.attachments.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.background,
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
      await ref.read(patientFolderProvider.notifier).fetch(refresh: true);

      if (!mounted) return;
      _showSnack('"${attachment.fileName}" deleted', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _showSnack(describeError(e, fallback: 'Failed to delete'), AppColors.error);
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

class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    required this.state,
    required this.fallbackName,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onBack,
  });

  final PatientFolderState state;
  final String? fallbackName;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final name = state.patientName != null
        ? "${state.patientName}'s Folder"
        : (fallbackName ?? 'Patient Folder');

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
              _BackButton(onPressed: onBack),
              const SizedBox(width: AppDimensions.paddingSmall),
              Container(
                width: AppDimensions.iconBadgeSize,
                height: AppDimensions.iconBadgeSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.folder_shared_rounded,
                  color: AppColors.primary,
                  size: AppDimensions.iconSize,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.titleLarge),
                    Text(
                      state.patientEmail ?? 'Files uploaded for this patient',
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
            hintText: 'Search in this folder...',
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
  const _ScopeIndicator({required this.canViewAny, required this.total});

  final bool canViewAny;
  final int total;

  @override
  Widget build(BuildContext context) {
    final label = canViewAny
        ? 'All uploads for this patient'
        : 'Your uploads for this patient';
    final icon =
        canViewAny ? Icons.groups_rounded : Icons.person_outline_rounded;
    final color = canViewAny ? AppColors.info : AppColors.primary;

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
              '$total file(s)',
              style: AppTextStyles.labelSmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _categories = <(String, String?)>[
    ('All', null),
    ('X-Rays', 'xray'),
    ('Photos', 'photo'),
    ('Consent', 'consent_form'),
    ('Lab Reports', 'lab_report'),
    ('Prescriptions', 'prescription'),
    ('Other', 'other'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppDimensions.paddingXS),
          itemBuilder: (context, index) {
            final (label, value) = _categories[index];
            final isSelected = selected == value;
            return _FilterChip(
              label: label,
              isSelected: isSelected,
              onTap: () => onSelected(value),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
            'Loading files...',
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
  const _EmptyState();

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
              'No files in this folder',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              'Upload files for this patient to see them here',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
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