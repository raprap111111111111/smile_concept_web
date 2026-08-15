// lib/presentation/pages/treatment_plans/widgets/form_section_card.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// A titled panel for one step of the treatment-plan form.
///
/// Carries an optional [step] number and a [complete] flag so the form reads as
/// a short, checkable sequence rather than one long scroll — the icon tile
/// swaps to a check once the section's required fields are filled.
class FormSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  /// 1-based position shown above the icon tile. Null hides the marker.
  final int? step;

  /// Drives the completed treatment (check icon + teal tile).
  final bool complete;

  const FormSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.step,
    this.complete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ─────────────────────────
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.line),
              ),
            ),
            child: Row(
              children: [
                _IconTile(icon: icon, complete: complete),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // One Text rather than a Row of parts: at 375px the
                      // trailing badge squeezes this line, and a Row of fixed
                      // children overflows where an ellipsis should happen.
                      Text.rich(
                        TextSpan(
                          children: [
                            if (step != null)
                              TextSpan(
                                text: 'STEP $step  ·  ',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            TextSpan(
                              text: complete ? 'Complete' : 'Required',
                              style: TextStyle(
                                color: complete
                                    ? AppColors.statusCompletedInk
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
          ),

          // ─── Body ───────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final bool complete;

  const _IconTile({required this.icon, required this.complete});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: AppDimensions.iconBadgeSize,
      width: AppDimensions.iconBadgeSize,
      decoration: BoxDecoration(
        color: complete
            ? AppColors.statusCompletedSoft
            : AppColors.accentWithOpacity(0.22),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: complete
              ? AppColors.statusCompletedInk.withValues(alpha: 0.25)
              : AppColors.accentWithOpacity(0.45),
        ),
      ),
      child: Icon(
        complete ? Icons.check_rounded : icon,
        color: complete ? AppColors.statusCompletedInk : AppColors.primaryDark,
        size: 22,
      ),
    );
  }
}
