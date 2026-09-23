import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Slowly spinning light rays behind a freshly unlocked card.
class SpinningRays extends StatefulWidget {
  const SpinningRays({super.key, required this.color, this.size = 760});
  final Color color;
  final double size;

  @override
  State<SpinningRays> createState() => _SpinningRaysState();
}

class _SpinningRaysState extends State<SpinningRays> with SingleTickerProviderStateMixin {
  late final _ac = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: widget.size,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const RadialGradient(
            colors: [Colors.black, Colors.black, Colors.transparent],
            stops: [0, .36, 1],
          ).createShader(rect),
          child: RotationTransition(
            turns: _ac,
            child: CustomPaint(painter: _RaysPainter(widget.color)),
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const rays = 16;
    final colors = <Color>[];
    final stops = <double>[];
    final c = color.withValues(alpha: .4);
    final t = color.withValues(alpha: 0);
    for (var i = 0; i < rays; i++) {
      final s = i / rays;
      final w = 1 / rays;
      colors.addAll([t, t, c, t]);
      stops.addAll([s, s + w * .4, s + w * .5, s + w * .6]);
    }
    colors.add(t);
    stops.add(1);
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = SweepGradient(colors: colors, stops: stops).createShader(rect));
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}

/// One-shot confetti burst from the center of the widget.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.colors, this.count = 80});
  final List<Color> colors;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Particle {
  _Particle(math.Random r, this.color)
      : round = r.nextDouble() < .35,
        w = 5 + r.nextDouble() * 4,
        rot = (r.nextDouble() * 720 - 360) * math.pi / 180,
        duration = 1.3 + r.nextDouble() * .7,
        delay = r.nextDouble() * .08 {
    final a = r.nextDouble() * math.pi * 2, d = 120 + r.nextDouble() * 220;
    target = Offset(math.cos(a) * d, math.sin(a) * d - 80);
  }

  final Color color;
  final bool round;
  final double w;
  final double rot;
  final double duration;
  final double delay;
  late final Offset target;
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 2100))..forward();
  late final List<_Particle> _parts;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _parts = List.generate(widget.count, (i) => _Particle(r, widget.colors[i % widget.colors.length]));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.zero,
        painter: _ConfettiPainter(_ac, _parts),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.anim, this.parts) : super(repaint: anim);
  final Animation<double> anim;
  final List<_Particle> parts;
  static const _curve = Cubic(.12, .75, .3, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = anim.value * 2.1;
    for (final p in parts) {
      final raw = ((seconds - p.delay) / p.duration).clamp(0.0, 1.0);
      if (raw <= 0) continue;
      Offset pos;
      double angle, scale, opacity;
      if (raw < .55) {
        final k = _curve.transform(raw / .55);
        pos = p.target * k;
        angle = p.rot * k;
        scale = .4 + .6 * k;
        opacity = 1;
      } else {
        final k = _curve.transform((raw - .55) / .45);
        pos = p.target + Offset(0, 170 * k);
        angle = p.rot * (1 + k);
        scale = 1 - .2 * k;
        opacity = 1 - k;
      }
      if (opacity <= 0) continue;
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      final glow = Paint()
        ..color = p.color.withValues(alpha: opacity * .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);
      canvas.scale(scale);
      final rect = Rect.fromCenter(center: Offset.zero, width: p.w, height: p.round ? p.w : p.w * 1.8);
      if (p.round) {
        canvas.drawOval(rect.inflate(2), glow);
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(3)), glow);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
