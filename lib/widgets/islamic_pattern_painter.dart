import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for Islamic geometric patterns
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  IslamicPatternPainter({required this.color, this.opacity = 0.05});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final spacing = 60.0;

    // Draw Islamic star pattern
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        _drawIslamicStar(canvas, Offset(x, y), 25, paint);
      }
    }
  }

  void _drawIslamicStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const points = 8;
    final angle = (math.pi * 2) / points;

    final path = Path();
    for (int i = 0; i < points; i++) {
      final x1 = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final y1 = center.dy + radius * math.sin(i * angle - math.pi / 2);

      final x2 =
          center.dx +
          (radius * 0.4) * math.cos((i + 0.5) * angle - math.pi / 2);
      final y2 =
          center.dy +
          (radius * 0.4) * math.sin((i + 0.5) * angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
    }
    path.close();

    canvas.drawPath(path, paint);

    // Draw inner circle
    canvas.drawCircle(center, radius * 0.3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
