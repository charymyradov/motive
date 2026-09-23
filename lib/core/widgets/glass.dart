import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/motive_colors.dart';

/// Frosted "glass" surface used across the app.
///
/// [blur] enables a real backdrop blur. It is kept off for items inside long
/// scrolling lists for performance; the blurred blobs behind already give the
/// surface its frosted look.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 26,
    this.padding,
    this.color,
    this.borderColor,
    this.blur = false,
    this.shadow = false,
    this.clip = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final bool blur;
  final bool shadow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final shape = BorderRadius.circular(radius);
    Widget box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.glass,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? c.line),
      ),
      child: child,
    );
    if (blur) {
      box = BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: box);
    }
    if (clip) box = ClipRRect(borderRadius: shape, child: box);
    if (!shadow) return box;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 60, spreadRadius: -12, offset: const Offset(0, 24))],
      ),
      child: box,
    );
  }
}
