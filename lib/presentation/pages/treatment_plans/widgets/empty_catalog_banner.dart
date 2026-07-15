// lib/presentation/pages/treatment_plans/widgets/empty_catalog_banner.dart

import 'package:flutter/material.dart';

class EmptyCatalogBanner extends StatelessWidget {
  const EmptyCatalogBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No treatments in catalog',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add treatments from the Treatments page first before creating a plan.',
                  style: TextStyle(
                      fontSize: 12, color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}