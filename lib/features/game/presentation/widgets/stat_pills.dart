import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';

/// Rounded counter shown in the feed header (streak and XP).
class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.icon, required this.value});

  final Widget icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      height: 32,
      padding: const EdgeInsets.fromLTRB(8, 0, 11, 0),
      decoration: BoxDecoration(color: c.glass2, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, .4), end: Offset.zero).animate(a), child: child),
            ),
            child: Text(value, key: ValueKey(value), style: AppText.sans(13, weight: FontWeight.w700, color: c.ink)),
          ),
        ],
      ),
    );
  }
}

class FlameIcon extends StatelessWidget {
  const FlameIcon({super.key, this.size = 14, this.active = true});
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? Palette.flame : null,
        color: active ? null : context.mc.line,
        boxShadow: active ? const [BoxShadow(color: Color(0xCCFF8C00), blurRadius: 12)] : null,
      ),
    );
  }
}

class XpIcon extends StatelessWidget {
  const XpIcon({super.key, this.size = 12});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: .785398,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Palette.xpA, Palette.xpB],
          ),
          boxShadow: const [BoxShadow(color: Color(0xCC9D7BFF), blurRadius: 12)],
        ),
      ),
    );
  }
}
