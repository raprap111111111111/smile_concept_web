// lib/presentation/pages/prescriptions/prescription_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/prescription/prescription_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/prescription/prescription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/prescription_item_tile.dart';

class PrescriptionDetailPage extends ConsumerStatefulWidget {
  final int prescriptionId;

  const PrescriptionDetailPage({
    super.key,
    required this.prescriptionId,
  });

  @override
  ConsumerState<PrescriptionDetailPage> createState() =>
      _PrescriptionDetailPageState();
}

class _PrescriptionDetailPageState
    extends ConsumerState<PrescriptionDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(prescriptionProvider.notifier)
          .loadById(widget.prescriptionId);
    });
  }

  AuthState get _auth => ref.read(authStateProvider);

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    if (!_auth.canDeletePrescription) {
      _showSnack(
        'You do not have permission to delete prescriptions',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          side: const BorderSide(color: AppColors.line),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Prescription',
                style: AppTextStyles.titleMedium),
          ],
        ),
        content: Text(
          'Are you sure you want to delete '
          'Prescription #${widget.prescriptionId}?\n\n'
          'This will also delete all medicines inside it. '
          'This action cannot be undone.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final success = await ref
        .read(prescriptionProvider.notifier)
        .deletePrescription(widget.prescriptionId);

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      _showSnack('Prescription deleted successfully');
      context.pop();
    } else {
      _showSnack(
        ref.read(prescriptionProvider).listError ??
            'Failed to delete prescription',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionProvider);
    final authState = ref.watch(authStateProvider);
    final canDelete = authState.canDeletePrescription;
    final canPrint = authState.canPrintPrescription;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back,
              color: AppColors.textSecondary),
        ),
        title: const Text('Prescription Details',
            style: AppTextStyles.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
        actions: [
          IconButton(
            onPressed: () => ref
                .read(prescriptionProvider.notifier)
                .loadById(widget.prescriptionId, forceRefresh: true),
            icon: const Icon(Icons.refresh_outlined,
                color: AppColors.textSecondary),
            tooltip: 'Refresh',
          ),
          if (canPrint)
            IconButton(
              onPressed: () =>
                  _showSnack('Print feature coming soon'),
              icon: const Icon(Icons.print_outlined,
                  color: AppColors.textSecondary),
              tooltip: 'Print Prescription',
            ),
          if (canDelete)
            IconButton(
              onPressed: _confirmAndDelete,
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error),
              tooltip: 'Delete Prescription',
            ),
          const SizedBox(width: AppDimensions.paddingSmall),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PrescriptionState state) {
    if (state.isDetailLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasDetailError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              const Text('Failed to load prescription',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
              Text(
                state.detailError ?? '',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(prescriptionProvider.notifier)
                    .loadById(widget.prescriptionId,
                        forceRefresh: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final prescription = state.selected;
    if (prescription == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PrescriptionHeaderCard(prescription: prescription),
              const SizedBox(height: AppDimensions.paddingLarge),

              // ── Medicines Section ───────────────────
              _SectionTitle(
                icon: Icons.medication_outlined,
                title: 'Medicines',
                subtitle: prescription.hasItems
                    ? '${prescription.items.length} prescribed'
                    : null,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              if (prescription.hasItems)
                ...prescription.items.asMap().entries.map(
                      (entry) => PrescriptionItemTile(
                        item: entry.value,
                        index: entry.key + 1,
                      ),
                    )
              else
                _EmptySection(
                  icon: Icons.medication_outlined,
                  message: 'No medicines listed',
                ),

              // ── Notes Section ───────────────────────
              if (prescription.hasNotes) ...[
                const SizedBox(height: AppDimensions.paddingLarge),
                _SectionTitle(
                  icon: Icons.sticky_note_2_outlined,
                  title: "Doctor's Notes",
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                      AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusLarge),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentWithOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.format_quote_outlined,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          prescription.notes!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.ink,
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.paddingXXL),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              subtitle!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Header Card ───────────────────────────────────────────────
class _PrescriptionHeaderCard extends StatelessWidget {
  final PrescriptionModel prescription;

  const _PrescriptionHeaderCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Gradient top bar ──────────────────────
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title Row ───────────────────────
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius),
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prescription #${prescription.id}',
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                prescription.formattedDate,
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ── Status badge ─────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.success
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.paddingMedium),
                const Divider(color: AppColors.line, height: 1),
                const SizedBox(height: AppDimensions.paddingMedium),

                // ── Info grid ────────────────────────
                if (prescription.doctor != null)
                  _InfoTile(
                    icon: Icons.person_outline,
                    label: 'Doctor',
                    value:
                        'Dr. ${prescription.doctor!.displayName}',
                    subValue: prescription.doctor!.specialty,
                    color: AppColors.primary,
                  ),
                if (prescription.patient != null) ...[
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.face_outlined,
                    label: 'Patient',
                    value: prescription.patient!.name,
                    subValue: prescription.patient!.email,
                    color: AppColors.info,
                  ),
                ],
                if (prescription.appointmentId != null) ...[
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.event_outlined,
                    label: 'Appointment',
                    value: '#${prescription.appointmentId}',
                    color: AppColors.warning,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.ink),
                ),
                if (subValue != null && subValue!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subValue!,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Section ─────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}