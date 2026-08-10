// lib/presentation/pages/lab_cases/lab_cases_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smile_concept_web/core/permissions/app_permissions.dart';
import 'package:smile_concept_web/presentation/widgets/common/permission_gate.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/theme/app_dimensions.dart';
import 'package:smile_concept_web/presentation/theme/app_text_styles.dart';
import 'package:smile_concept_web/presentation/pages/lab_cases/widgets/lab_case_card.dart';
import 'package:smile_concept_web/presentation/pages/lab_cases/widgets/lab_case_empty_state.dart';
import 'package:smile_concept_web/presentation/pages/lab_cases/widgets/lab_case_filters.dart';
import 'package:smile_concept_web/presentation/providers/lab_case/lab_case_provider.dart';
import 'package:smile_concept_web/presentation/route/route_names.dart';

class LabCasesPage extends ConsumerStatefulWidget {
  const LabCasesPage({super.key});

  @override
  ConsumerState<LabCasesPage> createState() => _LabCasesPageState();
}

class _LabCasesPageState extends ConsumerState<LabCasesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(labCaseProvider.notifier).fetchLabCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(labCaseProvider);
    final notifier = ref.read(labCaseProvider.notifier);

    ref.listen(labCaseProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        notifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: PermissionGate(
        permission: Perm.labCaseCreate,
        child: FloatingActionButton.extended(
          onPressed: () => context.pushNamed(RouteNames.labCaseCreate),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Lab Case',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchLabCases(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Header with icon + title + actions ──────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingXL,
                  AppDimensions.paddingXL,
                  AppDimensions.paddingXL,
                  AppDimensions.paddingMedium,
                ),
                child: Row(
                  children: [
                    // Icon in soft box
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius),
                      ),
                      child: Icon(Icons.science_outlined,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lab Cases',
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track dental work sent to external laboratories',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Filter icon
                    _CircleIconButton(
                      icon: Icons.filter_alt_outlined,
                      onTap: () {
                      },
                    ),
                    const SizedBox(width: 8),
                    // Refresh icon
                    _CircleIconButton(
                      icon: Icons.refresh,
                      onTap: () => notifier.fetchLabCases(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar + Search button ───────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXL,
                  vertical: AppDimensions.paddingSmall,
                ),
                child: const LabCaseFilters(),
              ),
            ),

            // ── Inline stat row (Total / Overdue / Received) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXL,
                  vertical: AppDimensions.paddingMedium,
                ),
                child: _InlineStats(state: state),
              ),
            ),

            // ── Content ────────────────────────────────────────
            if (state.isLoading)
              SliverToBoxAdapter(child: _buildSkeletons())
            else if (state.items.isEmpty)
              SliverToBoxAdapter(
                child: LabCaseEmptyState(
                  hasFilters:
                      state.search != null || state.statusFilter != null,
                  onResetFilters: () => notifier.resetFilters(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXL,
                ),
                sliver: SliverList.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final labCase = state.items[index];
                    return LabCaseCard(
                      labCase: labCase,
                      onDeleted: () async {
                        await notifier.deleteLabCase(labCase.id);
                      },
                    );
                  },
                ),
              ),

            // Bottom padding so FAB doesn't overlap last item
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXL,
      ),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin:
                const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Circle icon button (filter, refresh) ─────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

// ── Inline stat row (single card with 3 sections) ─────────────────────────

class _InlineStats extends StatelessWidget {
  final LabCaseState state;

  const _InlineStats({required this.state});

  @override
  Widget build(BuildContext context) {
    final overdue = state.items.where((l) => l.isOverdue).length;
    final received =
        state.items.where((l) => l.status == 'received').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatSegment(
            icon: Icons.science_outlined,
            value: state.total.toString(),
            label: 'Total',
            color: AppColors.primary,
          ),
          _Divider(),
          _StatSegment(
            icon: Icons.trending_down,
            value: overdue.toString(),
            label: 'Overdue',
            color: overdue > 0
                ? const Color(0xFFF59E0B)
                : AppColors.textSecondary,
          ),
          _Divider(),
          _StatSegment(
            icon: Icons.check_circle_outline,
            value: received.toString(),
            label: 'Received',
            color: received > 0
                ? AppColors.success
                : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatSegment extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatSegment({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingMedium,
          horizontal: AppDimensions.paddingSmall,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
    );
  }
}