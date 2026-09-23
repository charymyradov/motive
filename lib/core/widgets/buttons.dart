import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/motive_colors.dart';
import 'pressable.dart';

/// Filled, high-contrast pill (the `--solid` button of the prototype).
class SolidButton extends StatelessWidget {
  const SolidButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 58,
    this.fontSize = 16,
    this.enabled = true,
    this.glow = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final bool enabled;
  final bool glow;
  final EdgeInsets padding;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: enabled ? onTap : null,
      haptic: true,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.solid,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: glow
                ? const [BoxShadow(color: Color(0xB3A078FF), blurRadius: 40, spreadRadius: -10, offset: Offset(0, 10))]
                : null,
          ),
          child: Text(label, style: AppText.sans(fontSize, weight: FontWeight.w700, color: c.onSolid)),
        ),
      ),
    );
  }
}

/// Outlined glass pill.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 46,
    this.fontSize = 14,
    this.color,
    this.fill,
    this.borderColor,
    this.expand = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final Color? color;
  final Color? fill;
  final Color? borderColor;
  final bool expand;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      haptic: true,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill ?? c.glass2,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: borderColor ?? c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 6)],
            Text(label, style: AppText.sans(fontSize, weight: FontWeight.w700, color: color ?? c.ink)),
          ],
        ),
      ),
    );
  }
}

/// Small monospaced, letter-spaced caption ("TODAY'S DROP", "HYPOTHESIS"...).
class MonoLabel extends StatelessWidget {
  const MonoLabel(
    this.text, {
    super.key,
    this.size = 10,
    this.color,
    this.weight = FontWeight.w600,
    this.spacing = .16,
    this.glow = false,
  });

  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;
  final double spacing;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final col = color ?? context.mc.ink3;
    return Text(
      text,
      style: AppText.mono(
        size,
        weight: weight,
        color: col,
        letterSpacing: spacing,
        shadows: glow ? [Shadow(color: col, blurRadius: 12)] : null,
      ),
    );
  }
}

/// Glowing dot used as bullet / status light.
class GlowDot extends StatelessWidget {
  const GlowDot(this.color, {super.key, this.size = 8});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 10)],
      ),
    );
  }
}
