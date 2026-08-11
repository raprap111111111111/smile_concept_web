// lib/presentation/pages/consent/widgets/consent_card.dart
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
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovering
              ? AppColors.primary.withValues(alpha: 0.03)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(
            color: voided
                ? AppColors.error.withValues(alpha: 0.25)
                : (_hovering
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.border),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: 10,
              ),
              child: Row(
                children: [
                  // ── Status icon ──
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: voided
                          ? AppColors.error.withValues(alpha: 0.10)
                          : AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      voided
                          ? Icons.cancel_rounded
                          : Icons.check_circle_rounded,
                      color: voided ? AppColors.error : AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),

                  // ── Title + date ──
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.consent.template?.title ?? 'Untitled Consent',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFmt.format(widget.consent.signedAt.toLocal()),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // ── Patient ──
                  Expanded(
                    flex: 2,
                    child: _cell(
                      icon: Icons.person_outline_rounded,
                      text: widget.consent.patient?.name ?? '—',
                    ),
                  ),

                  // ── Signed by ──
                  Expanded(
                    flex: 2,
                    child: _cell(
                      icon: Icons.badge_outlined,
                      text: widget.consent.signedByStaff?.name ?? '—',
                    ),
                  ),

                  // ── Status badge ──
                  SizedBox(width: 70, child: _statusBadge(voided)),

                  // ── Actions ──
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      tooltip: 'View PDF',
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      color: AppColors.primary,
                      onPressed: () => _openPdf(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      tooltip: 'Download',
                      icon: const Icon(Icons.download_outlined, size: 18),
                      color: AppColors.primary,
                      onPressed: () => _openPdf(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(bool voided) {
    final color = voided ? AppColors.error : AppColors.success;
    final label = voided ? 'VOIDED' : 'VALID';
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.8,
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