import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/consent/patient_consents_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/error_display_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/consent_card.dart';
import 'widgets/consent_filter_bar.dart';
import 'widgets/sign_consent_dialog.dart';

class ConsentListPage extends ConsumerStatefulWidget {
  const ConsentListPage({super.key});

  @override
  ConsumerState<ConsentListPage> createState() => _ConsentListPageState();
}

class _ConsentListPageState extends ConsumerState<ConsentListPage> {
  final _searchController = TextEditingController();

  String? _searchQuery;
  String? _statusFilter; // 'valid' | 'voided' | null
  int _currentPage = 1;
  static const int _pageSize = 15;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().isEmpty ? null : query.trim();
      _currentPage = 1;
    });
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _statusFilter = status;
      _currentPage = 1;
    });
  }

  void _onRefresh() => ref.invalidate(patientConsentsProvider);

  Future<void> _onSignPressed() async {
    final result = await SignConsentDialog.show(context);
    if (result == true) _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final perm       = ref.watch(permissionServiceProvider);
    final canViewAny = perm.can(Perm.consentFormViewAny);
    final canSign    = perm.can(Perm.consentFormSign);

    final params = PatientConsentsParams(
      page:     _currentPage,
      pageSize: _pageSize,
    );
    final consentsAsync = ref.watch(patientConsentsProvider(params));

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: canSign
          ? FloatingActionButton.extended(
              onPressed: _onSignPressed,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Sign New Consent',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(canViewAny, consentsAsync),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildSearchBar(),
            const SizedBox(height: AppDimensions.paddingMedium),
            ConsentFilterBar(
              selectedStatus: _statusFilter,
              onStatusChanged: _onStatusChanged,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Expanded(
              child: consentsAsync.when(
                loading: () => const LoadingWidget(
                  message: 'Loading consent forms…',
                ),
                error: (e, _) => ErrorDisplayWidget(
                  error: e.toString(),
                  onRetry: _onRefresh,
                ),
                data: (result) {
                  final filtered = _applyClientFilters(result.records);
                  if (filtered.isEmpty) {
                    return _buildEmpty(canViewAny, canSign);
                  }
                  return _buildList(result, filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool canViewAny, AsyncValue consentsAsync) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: AppColors.textOnPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        canViewAny
                            ? 'All Consent Forms'
                            : 'My Consent Forms',
                        style: AppTextStyles.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Signed patient consent records',
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (consentsAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              _IconTile(
                tooltip: 'Refresh',
                icon: Icons.refresh_rounded,
                onTap: _onRefresh,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: 'Search by patient name or consent title…',
          hintStyle: AppTextStyles.inputHint,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchQuery == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
          filled: true,
          fillColor: AppColors.background,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingMedium,
          ),
        ),
      ),
    );
  }

  // ── LIST ──────────────────────────────────────────────────────────────────
  Widget _buildList(dynamic result, List filtered) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: filtered.length + 1,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDimensions.paddingSmall),
        itemBuilder: (context, index) {
          if (index == filtered.length) return _buildPaginationBar(result);
          final consent = filtered[index];
          return ConsentCard(
            consent: consent,
            onTap: () => context.pushNamed(
              RouteNames.consents,
              extra: consent,
            ),
          );
        },
      ),
    );
  }

  List _applyClientFilters(List records) {
    var list = records;

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final q = _searchQuery!.toLowerCase();
      list = list.where((c) {
        final title  = (c.template?.title ?? '').toLowerCase();
        final name   = (c.patient?.name ?? '').toLowerCase();
        return title.contains(q) || name.contains(q);
      }).toList();
    }

    if (_statusFilter != null) {
      list = list.where((c) {
        final voided = c.isVoided as bool;
        return _statusFilter == 'voided' ? voided : !voided;
      }).toList();
    }

    return list;
  }

  // ── PAGINATION ────────────────────────────────────────────────────────────
  Widget _buildPaginationBar(dynamic result) {
    final total   = result.total as int;
    final hasMore = result.hasMore as bool;

    if (total <= _pageSize) return const SizedBox.shrink();

    final start = ((_currentPage - 1) * _pageSize) + 1;
    final end   = (start + _pageSize - 1).clamp(1, total).clamp(start, total);

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.paddingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
            ),
            child: Text(
              '$start–$end of $total',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed:
                hasMore ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }

  // ── EMPTY ─────────────────────────────────────────────────────────────────
  Widget _buildEmpty(bool canViewAny, bool canSign) {
    final hasFilter = _searchQuery != null || _statusFilter != null;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        margin: const EdgeInsets.only(top: AppDimensions.paddingXL),
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              hasFilter
                  ? 'No matching consents'
                  : (canViewAny
                      ? 'No consent forms yet'
                      : 'No consents signed'),
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Try adjusting your search or filter'
                  : (canViewAny
                      ? 'Signed patient consents will appear here.'
                      : 'Your signed consents will appear here.'),
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (canSign && !hasFilter) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              FilledButton.icon(
                onPressed: _onSignPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Sign New Consent'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Reusable icon tile (matches Appointments page) ──────────────────────────
class _IconTile extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _IconTile({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
    );
  }
}