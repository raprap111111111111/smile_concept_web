// lib/presentation/pages/treatments/widgets/treatment_info_chip.dart

import 'package:flutter/material.dart';

class TreatmentInfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const TreatmentInfoChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical:   3,
      ),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize:   11,
              color:      color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}