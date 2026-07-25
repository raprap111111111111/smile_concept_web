// lib/presentation/widgets/shared/hold_to_delete_button.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoldToDeleteButton extends StatefulWidget {
  final String label;
  final String hintText;
  final Duration duration;
  final bool disabled;
  final bool loading;
  final VoidCallback? onComplete;

  const HoldToDeleteButton({
    super.key,
    this.label = 'Hold to delete',
    this.hintText = 'hold 2s',
    this.duration = const Duration(seconds: 2),
    this.disabled = false,
    this.loading = false,
    this.onComplete,
  });

  @override
  State<HoldToDeleteButton> createState() => _HoldToDeleteButtonState();
}

class _HoldToDeleteButtonState extends State<HoldToDeleteButton> {
  double _progress = 0.0;
  Timer? _timer;
  DateTime? _startTime;
  bool _completed = false;
  bool _isHovering = false;

  static const double _radius = 22.0;
  static const double _strokeWidth = 2.5;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (widget.disabled || widget.loading || _completed) return;

    HapticFeedback.lightImpact();
    _startTime = DateTime.now();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
      final newProgress =
          min(elapsed / widget.duration.inMilliseconds, 1.0);

      setState(() => _progress = newProgress);

      if (_progress >= 1.0) {
        timer.cancel();
        _timer = null;
        _completed = true;
        HapticFeedback.heavyImpact();
        widget.onComplete?.call();
      }
    });
  }

  void _stopHold() {
    if (_completed) return;
    _timer?.cancel();
    _timer = null;

    if (!mounted) return;
    setState(() => _progress = 0.0);
  }

  int get _progressPercent => (_progress * 100).round();

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.loading;
    final borderColor = _progress > 0
        ? const Color(0xFFDC2626)
        : _isHovering
            ? const Color(0xFFDC2626).withValues(alpha: 0.5)
            : const Color(0xFFE5D9C8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: MouseRegion(
            cursor: isDisabled
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) {
              setState(() => _isHovering = false);
              _stopHold();
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: isDisabled ? null : (_) => _startHold(),
              onPointerUp: (_) => _stopHold(),
              onPointerCancel: (_) => _stopHold(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _progress > 0
                      ? const Color(0xFFFEF2F2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _progress > 0
                          ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(48, 48),
                            painter: _RingPainter(
                              progress: _progress,
                              radius: _radius,
                              strokeWidth: _strokeWidth,
                              trackColor: const Color(0xFFE8D9BF),
                              progressColor: const Color(0xFFDC2626),
                            ),
                          ),
                          widget.loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFDC2626),
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 22,
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.loading ? 'Deleting...' : widget.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E2D4E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.hintText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$_progressPercent%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _progress > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFCBBDA0),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFFF1EBE0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFEF4444)),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double radius;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  const _RingPainter({
    required this.progress,
    required this.radius,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}