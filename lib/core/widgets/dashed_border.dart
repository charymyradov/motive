import 'dart:ui';

import 'package:flutter/material.dart';

/// Draws a dashed rounded-rectangle border around [child].
class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, required this.child, required this.color, this.radius = 30, this.dash = 6, this.gap = 5});

  final Widget child;
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(color, radius, dash, gap),
      child: child,
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.radius, this.dash, this.gap);
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
