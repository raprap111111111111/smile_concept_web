// lib/presentation/pages/treatment_plans/widgets/treatment_plan_status_filter.dart

import 'package:flutter/material.dart';

class TreatmentPlanStatusFilter extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const TreatmentPlanStatusFilter({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  String _label(String s) => switch (s) {
        'all'       => 'All',
        'draft'     => 'Draft',
        'proposed'  => 'Proposed',
        'accepted'  => 'Accepted',
        'completed' => 'Completed',
        'rejected'  => 'Rejected',
        _           => s,
      };

  Color _color(String s) => switch (s) {
        'accepted'  => Colors.green,
        'completed' => Colors.teal,
        'rejected'  => Colors.red,
        'proposed'  => Colors.orange,
        'draft'     => Colors.grey,
        _           => Colors.blue,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color:  Theme.of(context).colorScheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        itemCount:        options.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status   = options[index];
          final isActive = selected == status;
          final color    = _color(status);

          return GestureDetector(
            onTap: () => onChanged(status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? color
                      : Colors.grey
                          .withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _label(status),
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}