// lib/presentation/pages/treatments/widgets/treatment_empty_state.dart

import 'package:flutter/material.dart';

class TreatmentEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const TreatmentEmptyState({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size:  72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Treatments Found',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:      Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No treatment catalog entries yet.\n'
              'Add treatments to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon:  const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}