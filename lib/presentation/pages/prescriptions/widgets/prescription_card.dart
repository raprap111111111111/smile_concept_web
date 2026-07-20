// lib/presentation/pages/prescriptions/widgets/prescription_card.dart

import 'package:flutter/material.dart';
import '../../../../data/models/prescription/prescription_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class PrescriptionCard extends StatefulWidget {
  final PrescriptionModel prescription;
  final VoidCallback onTap;

  const PrescriptionCard({
    super.key,
    required this.prescription,
    required this.onTap,
  });

  @override
  State<PrescriptionCard> createState() => _PrescriptionCardState();
}

class _PrescriptionCardState extends State<PrescriptionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prescription;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(
            color: _isHovered ? AppColors.primary : AppColors.line,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusLarge),
            child: Padding(
              padding:
                  const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row ──────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.accentWithOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadius),
                        ),
                        child: const Icon(
                          Icons.medication_outlined,
                          color: AppColors.primaryDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title + Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prescription #${p.id}',
                              style: AppTextStyles.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  p.formattedDate,
                                  style: AppTextStyles.labelSmall
                                      .copyWith(
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Item badge
                      if (p.hasItems)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accentWithOpacity(0.12),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: AppColors.accentWithOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.medication_outlined,
                                size: 12,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${p.items.length} med${p.items.length > 1 ? 's' : ''}',
                                style: AppTextStyles.labelSmall
                                    .copyWith(
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // ── Doctor & Patient info ────────────────
                  if (p.doctor != null || p.patient != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius),
                      ),
                      child: Column(
                        children: [
                          if (p.doctor != null)
                            _InlineInfo(
                              icon: Icons.person_outline,
                              label:
                                  'Dr. ${p.doctor!.displayName}',
                              sublabel: p.doctor!.specialty,
                            ),
                          if (p.doctor != null && p.patient != null)
                            const SizedBox(height: 8),
                          if (p.patient != null)
                            _InlineInfo(
                              icon: Icons.face_outlined,
                              label: p.patient!.name,
                            ),
                        ],
                      ),
                    ),
                  ],

                  // ── Medicine chips ───────────────────────
                  if (p.hasItems) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...p.items.take(3).map(
                              (item) => _MedChip(
                                label: item.medicineName,
                              ),
                            ),
                        if (p.items.length > 3)
                          _MedChip(
                            label: '+${p.items.length - 3} more',
                            highlight: true,
                          ),
                      ],
                    ),
                  ],

                  // ── Notes ────────────────────────────────
                  if (p.hasNotes) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius),
                        border: const Border(
                          left: BorderSide(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.sticky_note_2_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.notes!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Inline Info ───────────────────────────────────────────────
class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;

  const _InlineInfo({
    required this.icon,
    required this.label,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.ink),
              children: [
                if (sublabel != null && sublabel!.trim().isNotEmpty)
                  TextSpan(
                    text: ' · $sublabel',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Medicine Chip ─────────────────────────────────────────────
class _MedChip extends StatelessWidget {
  final String label;
  final bool highlight;

  const _MedChip({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.line,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: highlight ? AppColors.primary : AppColors.ink,
        ),
      ),
    );
  }
}