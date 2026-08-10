import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/consent/patient_consent_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/shared/pdf_viewer_page.dart';

class ConsentCard extends ConsumerStatefulWidget {
  final PatientConsentModel consent;
  final VoidCallback? onTap;

  const ConsentCard({
    super.key,
    required this.consent,
    this.onTap,
  });

  @override
  ConsumerState<ConsentCard> createState() => _ConsentCardState();
}

class _ConsentCardState extends ConsumerState<ConsentCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final voided  = widget.consent.isVoided;
    final dateFmt = DateFormat('MMM d, y • h:mm a');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(
            color: voided
                ? AppColors.error.withValues(alpha: 0.35)
                : (_hovering
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.border),
            width: _hovering ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovering
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : AppColors.cardShadow,
              blurRadius: _hovering ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(voided, dateFmt),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildMeta(),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  _buildActions(context, voided),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader(bool voided, DateFormat dateFmt) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: voided
                ? AppColors.error.withValues(alpha: 0.10)
                : AppColors.accentLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: voided
                  ? AppColors.error.withValues(alpha: 0.25)
                  : AppColors.border,
            ),
          ),
          child: Icon(
            voided ? Icons.cancel_rounded : Icons.check_circle_rounded,
            color: voided ? AppColors.error : AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.consent.template?.title ?? 'Untitled Consent',
                style: AppTextStyles.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Signed ${dateFmt.format(widget.consent.signedAt.toLocal())}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (voided) _buildBadge('VOIDED', AppColors.error)
        else       _buildBadge('VALID',  AppColors.success),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── META CHIPS ──────────────────────────────────────────────────────────
  Widget _buildMeta() {
    final chips = <Widget>[];

    if (widget.consent.patient != null) {
      chips.add(_metaChip(
        Icons.person_outline_rounded,
        widget.consent.patient!.name,
        AppColors.primary,
      ));
    }
    if (widget.consent.appointment != null) {
      chips.add(_metaChip(
        Icons.event_outlined,
        'Appt #${widget.consent.appointment!.id}',
        AppColors.warning,
      ));
    }
    if (widget.consent.signedByStaff != null) {
      chips.add(_metaChip(
        Icons.badge_outlined,
        widget.consent.signedByStaff!.name,
        AppColors.textSecondary,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _metaChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTIONS ─────────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context, bool voided) {
    return Row(
      children: [
        _actionButton(
          icon: Icons.visibility_outlined,
          label: 'View',
          onPressed: () => _openPdf(context),
        ),
        const SizedBox(width: 4),
        _actionButton(
          icon: Icons.download_outlined,
          label: 'Download',
          onPressed: () => _openPdf(context),
        ),
        const Spacer(),
        const Icon(
          Icons.arrow_forward_rounded,
          size: 16,
          color: AppColors.textTertiary,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _openPdf(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          title: widget.consent.template?.title ?? 'Consent PDF',
          consentId: widget.consent.id,
        ),
      ),
    );
  }
}