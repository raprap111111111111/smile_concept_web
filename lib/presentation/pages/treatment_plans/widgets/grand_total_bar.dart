// lib/presentation/pages/treatment_plans/widgets/grand_total_bar.dart

import 'package:flutter/material.dart';

class GrandTotalBar extends StatelessWidget {
  final double total;
  final int itemCount;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const GrandTotalBar({
    super.key,
    required this.total,
    required this.itemCount,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
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
                    'Grand Total',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.hintColor,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· $itemCount item${itemCount == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 13, color: theme.hintColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(isSubmitting ? 'Creating...' : 'Create Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}