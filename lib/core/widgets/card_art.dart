import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One soft radial light spot of a card background
/// (a `radial-gradient(... at x% y%, color 0%, transparent stop%)` in CSS).
class GradientSpot {
  const GradientSpot(this.center, this.color, {this.radius = 1.1, this.stop = .55});
  final Alignment center;
  final Color color;
  final double radius;
  final double stop;
}

/// Layered radial-gradient background of a collectible card.
class CardArtBackground extends StatelessWidget {
  const CardArtBackground({
    super.key,
    required this.base,
    required this.spots,
    this.foil = false,
  });

  final Color base;
  final List<GradientSpot> spots;
  final bool foil;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        for (final s in spots)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: s.center,
                radius: s.radius,
                colors: [s.color, s.color.withValues(alpha: 0)],
                stops: [0, s.stop],
              ),
            ),
          ),
        if (foil)
          const CustomPaint(
            painter: StripesPainter(color: Color(0x0BFFFFFF), angle: 115, width: 2, period: 7),
          ),
      ],
    );
  }
}

/// Repeating thin diagonal lines (`repeating-linear-gradient`).
class StripesPainter extends CustomPainter {
  const StripesPainter({
    required this.color,
    required this.angle,
    required this.width,
    required this.period,
  });

  final Color color;

  /// CSS gradient angle in degrees.
  final double angle;
  final double width;
  final double period;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final diag = math.sqrt(size.width * size.width + size.height * size.height);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate((angle - 90) * math.pi / 180);
    for (var x = -diag / 2; x < diag / 2; x += period) {
      canvas.drawRect(Rect.fromLTWH(x, -diag / 2, width, diag), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(StripesPainter old) =>
      old.color != color || old.angle != angle || old.width != width || old.period != period;
}

/// The glowing concentric "sigil" in the middle of every unlocked card.
class CardSigil extends StatelessWidget {
  const CardSigil({super.key, required this.size, required this.glow, this.inner = true});

  final double size;
  final Color glow;
  final bool inner;

  @override
  Widget build(BuildContext context) {
    final dot = math.max(6.0, size * .12);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x59FFFFFF)),
              gradient: const RadialGradient(colors: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x2EFFFFFF)], stops: [0, .6, 1]),
              boxShadow: [BoxShadow(color: glow, blurRadius: size * .43)],
            ),
          ),
          if (inner)
            Container(
              width: size * .6,
              height: size * .6,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x47FFFFFF))),
            ),
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xBFFFFFFF), blurRadius: dot * 1.9, spreadRadius: dot * .55)],
            ),
          ),
        ],
      ),
    );
  }
}
