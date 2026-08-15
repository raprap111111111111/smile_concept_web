// lib/presentation/pages/treatment_plans/widgets/grand_total_bar.dart
import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

/// Sticky action bar for narrow layouts, where the summary rail is hidden.
///
/// Surfaces the running total plus the first unmet requirement, so the submit
/// button never fails for a reason the clinician cannot see from here.
class GrandTotalBar extends StatelessWidget {
  final double total;
  final int itemCount;
  final bool isSubmitting;

  /// First outstanding requirement, or null when the plan is ready.
  final String? blockedReason;

  final VoidCallback onSubmit;

  const GrandTotalBar({
    super.key,
    required this.total,
    required this.itemCount,
    required this.isSubmitting,
    required this.onSubmit,
    this.blockedReason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: AppDimensions.paddingSmall,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Grand total · $itemCount '
                    'step${itemCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatMoney(total),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  if (blockedReason != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 12,
                          color: AppColors.statusPendingInk,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            blockedReason!,
                            style: const TextStyle(
                              color: AppColors.statusPendingInk,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(isSubmitting ? 'Saving…' : 'Create Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
