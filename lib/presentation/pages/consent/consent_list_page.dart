// lib/presentation/pages/consent/consent_list_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/consent/patient_consents_provider.dart';
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Search (debounced) ──────────────────────────────────────────────────
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = value.trim();
      final current = ref.read(consentFilterProvider);
      ref.read(consentFilterProvider.notifier).state = current.copyWith(
        search: trimmed.isEmpty ? null : trimmed,
        clearSearch: trimmed.isEmpty,
        page: 1,
      );
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    final current = ref.read(consentFilterProvider);
    ref.read(consentFilterProvider.notifier).state =
        current.copyWith(clearSearch: true, page: 1);
  }

  // ── Status filter ───────────────────────────────────────────────────────
  void _onStatusChanged(String? status) {
    final current = ref.read(consentFilterProvider);
    ref.read(consentFilterProvider.notifier).state = current.copyWith(
      status: status,
      clearStatus: status == null,
      page: 1,
    );
  }

  // ── Pagination ──────────────────────────────────────────────────────────
  void _onPageChanged(int newPage) {
    final current = ref.read(consentFilterProvider);
    ref.read(consentFilterProvider.notifier).state =
        current.copyWith(page: newPage);
  }

  void _onRefresh() => ref.invalidate(patientConsentsProvider);

  Future<void> _onSignPressed() async {
    final result = await SignConsentDialog.show(context);
    if (result == true) _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final perm = ref.watch(permissionServiceProvider);
    final canViewAny = perm.can(Perm.consentFormViewAny);
    final canSign = perm.can(Perm.consentFormSign);

    final filter = ref.watch(consentFilterProvider);
    final consentsAsync = ref.watch(patientConsentsProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ConsentsHeader(
              title: canViewAny ? 'All Consent Forms' : 'My Consent Forms',
              subtitle: 'Signed patient consent records',
              isLoading: consentsAsync.isLoading,
              canSign: canSign,
              onRefresh: _onRefresh,
              onSign: _onSignPressed,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Search + Filter row ──
            Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: AppDimensions.paddingMedium),
                ConsentFilterBar(
                  selectedStatus: filter.status,
                  onStatusChanged: _onStatusChanged,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Body ──
            Expanded(
              child: consentsAsync.when(
                loading: () =>
                    const LoadingWidget(message: 'Loading consent forms…'),
                error: (e, _) => ErrorDisplayWidget(
                  error: e.toString(),
                  onRetry: _onRefresh,
                ),
                data: (result) {
                  if (result.records.isEmpty) {
                    return _ConsentsEmptyState(
                      hasFilter: filter.search != null || filter.status != null,
                      canViewAny: canViewAny,
                      canSign: canSign,
                      onSign: _onSignPressed,
                    );
                  }
                  return _buildTable(result, filter);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search field ────────────────────────────────────────────────────────
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
        decoration: InputDecoration(
          hintText: 'Search by patient name or consent title…',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: AppDimensions.iconSize,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: _onClearSearch,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingMedium,
          ),
        ),
      ),
    );
  }

  // ── Table (header + rows + pagination) ─────────────────────────────────
  Widget _buildTable(dynamic result, PatientConsentsParams filter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TableHeader(),
        const SizedBox(height: 6),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _onRefresh(),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: result.records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final consent = result.records[index];
                return ConsentCard(
                  consent: consent,
                  onTap: () => context.pushNamed(
                    'consent-detail',
                    pathParameters: {'id': '${consent.id}'},
                  ),
                );
              },
            ),
          ),
        ),
        _PaginationBar(
          currentPage: filter.page,
          pageSize: filter.pageSize,
          total: result.total as int,
          lastPage: result.lastPage as int,
          onPageChanged: _onPageChanged,
        ),
      ],
    );
  }
}

// ─── Header (with Sign New Consent button) ──────────────────────────────────
class _ConsentsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLoading;
  final bool canSign;
  final VoidCallback onRefresh;
  final VoidCallback onSign;

  const _ConsentsHeader({
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.canSign,
    required this.onRefresh,
    required this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Title ──
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusLarge,
                ),
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: Colors.white,
                size: AppDimensions.iconBadgeSize * 0.6,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),

        // ── Actions ──
        Row(
          children: [
            if (isLoading)
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
            ),
            if (canSign) ...[
              const SizedBox(width: AppDimensions.paddingSmall),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onSign,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLarge,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Sign New Consent',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Table Header Row ───────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // icon col placeholder (matches ConsentCard icon width)
          const SizedBox(width: 32 + AppDimensions.paddingMedium),
          Expanded(flex: 3, child: _label('CONSENT')),
          Expanded(flex: 2, child: _label('PATIENT')),
          Expanded(flex: 2, child: _label('SIGNED BY')),
          SizedBox(width: 70, child: _label('STATUS', center: true)),
          // action buttons placeholder (view + download + chevron)
          const SizedBox(width: 8 + 40 + 40 + 20),
        ],
      ),
    );
  }

  Widget _label(String text, {bool center = false}) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────
class _ConsentsEmptyState extends StatelessWidget {
  final bool hasFilter;
  final bool canViewAny;
  final bool canSign;
  final VoidCallback onSign;

  const _ConsentsEmptyState({
    required this.hasFilter,
    required this.canViewAny,
    required this.canSign,
    required this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            hasFilter
                ? 'No matching consents'
                : (canViewAny ? 'No consent forms yet' : 'No consents signed'),
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            hasFilter
                ? 'Try adjusting your search or filter'
                : 'Signed patient consents will appear here.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (canSign && !hasFilter) ...[
            const SizedBox(height: AppDimensions.paddingLarge),
            FilledButton.icon(
              onPressed: onSign,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Sign New Consent'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Pagination Bar ─────────────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int pageSize;
  final int total;
  final int lastPage;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.pageSize,
    required this.total,
    required this.lastPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    final start = ((currentPage - 1) * pageSize) + 1;
    final end = (currentPage * pageSize).clamp(start, total);

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.paddingMedium),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left: Page X of Y ──
          Text(
            'Page $currentPage of $lastPage',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),

          // ── Middle: Navigation controls ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavBtn(
                icon: Icons.first_page_rounded,
                tooltip: 'First page',
                enabled: currentPage > 1,
                onTap: () => onPageChanged(1),
              ),
              const SizedBox(width: 4),
              _NavBtn(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous',
                enabled: currentPage > 1,
                onTap: () => onPageChanged(currentPage - 1),
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(),
              const SizedBox(width: 8),
              _NavBtn(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next',
                enabled: currentPage < lastPage,
                onTap: () => onPageChanged(currentPage + 1),
              ),
              const SizedBox(width: 4),
              _NavBtn(
                icon: Icons.last_page_rounded,
                tooltip: 'Last page',
                enabled: currentPage < lastPage,
                onTap: () => onPageChanged(lastPage),
              ),
            ],
          ),

          // ── Right: Showing X–Y of Z ──
          Text(
            'Showing $start–$end of $total',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds numbered page buttons with ellipsis for long ranges.
  List<Widget> _buildPageNumbers() {
    final pages = _computeVisiblePages();
    return pages.map((page) {
      if (page == -1) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '…',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      return _PageNumberBtn(
        page: page,
        active: page == currentPage,
        onTap: () => onPageChanged(page),
      );
    }).toList();
  }

  /// Returns a list of pages to show. Use -1 for ellipsis.
  ///   1 total    → [1]
  ///   5 total    → [1, 2, 3, 4, 5]
  ///   10, cur=1  → [1, 2, 3, 4, 5, -1, 10]
  ///   10, cur=5  → [1, -1, 4, 5, 6, -1, 10]
  ///   10, cur=10 → [1, -1, 6, 7, 8, 9, 10]
  List<int> _computeVisiblePages() {
    if (lastPage <= 7) {
      return List.generate(lastPage, (i) => i + 1);
    }

    final pages = <int>[1];

    if (currentPage > 3) pages.add(-1);

    final rangeStart = (currentPage - 1).clamp(2, lastPage - 1);
    final rangeEnd = (currentPage + 1).clamp(2, lastPage - 1);

    for (var p = rangeStart; p <= rangeEnd; p++) {
      if (!pages.contains(p)) pages.add(p);
    }

    if (currentPage < lastPage - 2) pages.add(-1);

    if (!pages.contains(lastPage)) pages.add(lastPage);

    return pages;
  }
}

// ─── Nav Button (first / prev / next / last) ────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.textSecondary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Page Number Button ─────────────────────────────────────────────────────
class _PageNumberBtn extends StatelessWidget {
  final int page;
  final bool active;
  final VoidCallback onTap;

  const _PageNumberBtn({
    required this.page,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: active ? null : onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: active ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    active ? AppColors.textOnPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
