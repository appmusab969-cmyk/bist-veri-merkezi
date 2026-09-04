import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dairesel ilerleme göstergesi — genel sağlık skoru (0–100).
class HealthRing extends StatelessWidget {
  const HealthRing({
    super.key,
    required this.score,
    this.size = 52,
    this.stroke = 5,
  });

  final int score;
  final double size;
  final double stroke;

  Color _color(ColorScheme c) {
    if (score >= 65) return c.primary;
    if (score >= 45) return c.tertiary;
    return c.error;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: (score / 100).clamp(0.0, 1.0),
          color: _color(colors),
          track: colors.outline,
          stroke: stroke,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: colors.onSurface,
                ),
              ),
              Text('/100',
                  style: text.labelSmall?.copyWith(
                    fontSize: 8,
                    height: 1,
                    color: colors.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double fraction;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}
