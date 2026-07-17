// lib/presentation/pages/clinical_records/clinical_records_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/presentation/constant/permission_constants.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/clinical_records/clinical_records_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/clinical_module_card.dart';
import 'widgets/clinical_stats_row.dart';
import 'widgets/recent_activity_list.dart';
import 'widgets/quick_actions_bar.dart';

class ClinicalRecordsPage extends ConsumerStatefulWidget {
  const ClinicalRecordsPage({super.key});

  @override
  ConsumerState<ClinicalRecordsPage> createState() =>
      _ClinicalRecordsPageState();
}

class _ClinicalRecordsPageState
    extends ConsumerState<ClinicalRecordsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load({bool forceRefresh = false}) {
    ref
        .read(clinicalRecordsProvider.notifier)
        .loadSummary(forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clinicalRecordsProvider);
    final auth = ref.watch(authStateProvider);

    // ── Permission gates ────────────────────────────────────
    final canViewDentalCharts =
        auth.hasPermission(Perm.dentalChartViewAny);
    final canViewClinicalNotes =
        auth.hasPermission(Perm.clinicalNoteViewAny);
    final canViewLabCases =
        auth.hasPermission(Perm.labCaseViewAny);
    final canViewAttachments =
        auth.hasPermission(Perm.attachmentViewAny);
    final canViewPrescriptions =
        auth.hasPermission(Perm.prescriptionViewAny);
    final canViewConsents =
        auth.hasPermission(Perm.consentFormViewAny);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Clinical Records',
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          IconButton(
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(
        state,
        auth,
        canViewDentalCharts: canViewDentalCharts,
        canViewClinicalNotes: canViewClinicalNotes,
        canViewLabCases: canViewLabCases,
        canViewAttachments: canViewAttachments,
        canViewPrescriptions: canViewPrescriptions,
        canViewConsents: canViewConsents,
      ),
    );
  }

  Widget _buildBody(
    ClinicalRecordsState state,
    AuthState auth, {
    required bool canViewDentalCharts,
    required bool canViewClinicalNotes,
    required bool canViewLabCases,
    required bool canViewAttachments,
    required bool canViewPrescriptions,
    required bool canViewConsents,
  }) {
    if (state.isLoading && state.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.summary == null) {
      return _buildError(state.error!);
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clinicalRecordsProvider.notifier).refresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ───────────────────────────────
            _buildHeader(),
            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Quick stats ─────────────────────────────────
            if (state.summary != null)
              ClinicalStatsRow(stats: state.summary!.stats),

            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Quick Actions ───────────────────────────────
            QuickActionsBar(auth: auth),

            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Module Cards Grid ───────────────────────────
            Text(
              'Clinical Modules',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            _buildModulesGrid(
              canViewDentalCharts: canViewDentalCharts,
              canViewClinicalNotes: canViewClinicalNotes,
              canViewLabCases: canViewLabCases,
              canViewAttachments: canViewAttachments,
              canViewPrescriptions: canViewPrescriptions,
              canViewConsents: canViewConsents,
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Recent Activity ─────────────────────────────
            if (state.summary != null &&
                state.summary!.recentActivity.isNotEmpty) ...[
              Text(
                'Recent Activity',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              RecentActivityList(
                activities: state.summary!.recentActivity,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.medical_information_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Electronic Health Records',
                  style: AppTextStyles.headlineOnDark.copyWith(
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage dental charts, notes, prescriptions & more',
                  style: AppTextStyles.bodyOnDark.copyWith(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid({
    required bool canViewDentalCharts,
    required bool canViewClinicalNotes,
    required bool canViewLabCases,
    required bool canViewAttachments,
    required bool canViewPrescriptions,
    required bool canViewConsents,
  }) {
    final modules = <Widget>[
      if (canViewClinicalNotes)
        ClinicalModuleCard(
          icon: Icons.note_alt_outlined,
          title: 'Clinical Notes',
          subtitle: 'Progress notes & sessions',
          color: AppColors.info,
          onTap: () => context.pushNamed(RouteNames.clinicalNotes),
        ),
      if (canViewDentalCharts)
        ClinicalModuleCard(
          icon: Icons.medical_services_outlined,
          title: 'Dental Charts',
          subtitle: 'Tooth-level records',
          color: AppColors.primary,
          onTap: () => context.pushNamed(RouteNames.dentalCharts),
        ),
      if (canViewPrescriptions)
        ClinicalModuleCard(
          icon: Icons.medication_outlined,
          title: 'Prescriptions',
          subtitle: 'Medicines & dosages',
          color: AppColors.success,
          onTap: () => context.pushNamed(RouteNames.prescriptions),
        ),
      if (canViewLabCases)
        ClinicalModuleCard(
          icon: Icons.science_outlined,
          title: 'Lab Cases',
          subtitle: 'Crowns, bridges & lab work',
          color: AppColors.warning,
          onTap: () => context.pushNamed(RouteNames.labCases),
        ),
      if (canViewAttachments)
        ClinicalModuleCard(
          icon: Icons.attach_file_outlined,
          title: 'Attachments',
          subtitle: 'X-rays, photos & files',
          color: AppColors.accent,
          onTap: () => context.pushNamed(RouteNames.patientAttachments),
        ),
      if (canViewConsents)
        ClinicalModuleCard(
          icon: Icons.assignment_outlined,
          title: 'Consent Forms',
          subtitle: 'Signed documents',
          color: AppColors.secondary,
          onTap: () => context.pushNamed(RouteNames.consents),
        ),
    ];

    if (modules.isEmpty) {
      return _buildNoAccess();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          childAspectRatio: 1.8,
          crossAxisSpacing: AppDimensions.paddingMedium,
          mainAxisSpacing: AppDimensions.paddingMedium,
          children: modules,
        );
      },
    );
  }

  Widget _buildNoAccess() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'No clinical modules available',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'You don\'t have permission to view any clinical records.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppDimensions.paddingMedium),
            ElevatedButton.icon(
              onPressed: () => _load(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}