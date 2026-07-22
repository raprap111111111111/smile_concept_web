// lib/presentation/pages/dashboard/components/charts/sparkline.dart
import 'package:flutter/material.dart';

import '../../../../theme/chart_palette.dart';

/// The trend strip inside a stat tile: a 2px line with a light wash beneath and
/// a single end-dot. No axes, no labels — the tile's value is the message and
/// the sparkline only shows its shape.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 34,
  });

  final List<int> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final span = (maxValue - minValue) == 0 ? 1 : (maxValue - minValue);

    // Inset so the 2px stroke and the end-dot never clip at the edges.
    const inset = 5.0;
    final usableHeight = size.height - inset * 2;
    final stepX = size.width / (values.length - 1);

    Offset pointAt(int index) {
      final normalized = (values[index] - minValue) / span;
      return Offset(
        stepX * index,
        inset + usableHeight - (normalized * usableHeight),
      );
    }

    final linePath = Path()..moveTo(0, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final point = pointAt(i);
      linePath.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()..color = color.withValues(alpha: 0.10),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // End-dot with a 2px surface ring so it stays legible over the wash.
    final last = pointAt(values.length - 1);
    canvas.drawCircle(last, 4, Paint()..color = ChartPalette.surface);
    canvas.drawCircle(last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
