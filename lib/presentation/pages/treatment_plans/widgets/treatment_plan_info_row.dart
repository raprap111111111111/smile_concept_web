// lib/presentation/pages/treatment_plans/widgets/treatment_plan_info_row.dart

import 'package:flutter/material.dart';

class TreatmentPlanInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;

  const TreatmentPlanInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (sub != null && sub!.isNotEmpty)
                Text(
                  sub!,
                  style: TextStyle(
                    fontSize: 11,
                    color:    Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}