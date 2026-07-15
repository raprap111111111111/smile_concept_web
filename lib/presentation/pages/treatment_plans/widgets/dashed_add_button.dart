// lib/presentation/pages/treatment_plans/widgets/dashed_add_button.dart

import 'package:flutter/material.dart';

class DashedAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const DashedAddButton({
    super.key,
    required this.onTap,
    this.label = 'Add Treatment',
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return CustomPaint(
      painter: _DashedRRectPainter(c.withValues(alpha: 0.6), 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: c),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(color: c, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedRRectPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}