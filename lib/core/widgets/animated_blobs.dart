import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/motive_colors.dart';

/// Three softly glowing color blobs drifting behind the whole UI.
///
/// Drawn as radial gradients in a single [CustomPainter] which is far cheaper
/// than blurring real shapes every frame.
class AnimatedBlobs extends StatefulWidget {
  const AnimatedBlobs({super.key});

  @override
  State<AnimatedBlobs> createState() => _AnimatedBlobsState();
}

class _AnimatedBlobsState extends State<AnimatedBlobs> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _elapsed = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _elapsed.value = d.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: _BlobPainter(_elapsed, [c.blob1, c.blob2, c.blob3]),
        ),
      ),
    );
  }
}

class _Blob {
  const _Blob(this.size, this.x, this.y, this.dx, this.dy, this.s0, this.s1, this.seconds);
  final double size, x, y, dx, dy, s0, s1, seconds;
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.elapsed, this.colors) : super(repaint: elapsed);

  final ValueNotifier<double> elapsed;
  final List<Color> colors;

  // Geometry of the prototype, designed for a 390 x 844 screen.
  static const _blobs = [
    _Blob(320, -110, -60, 70, 140, 1.0, 1.3, 16),
    _Blob(280, 200, 360, -80, -120, 1.1, 0.9, 19),
    _Blob(240, -60, 620, 50, -90, 0.9, 1.2, 22),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390, sy = size.height / 844;
    final t = elapsed.value;
    for (var i = 0; i < _blobs.length; i++) {
      final b = _blobs[i];
      // ease-in-out ping-pong between 0 and 1
      final p = (1 - math.cos(math.pi * t / b.seconds)) / 2;
      final scale = b.s0 + (b.s1 - b.s0) * p;
      final r = b.size / 2 * scale * sx;
      final center = Offset((b.x + b.size / 2 + b.dx * p) * sx, (b.y + b.size / 2 + b.dy * p) * sy);
      final glowR = r + 70 * sx;
      final color = colors[i];
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: .55), color.withValues(alpha: .3), color.withValues(alpha: 0)],
          stops: [0, r / glowR * .7, 1],
        ).createShader(Rect.fromCircle(center: center, radius: glowR));
      canvas.drawCircle(center, glowR, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.colors != colors;
}
