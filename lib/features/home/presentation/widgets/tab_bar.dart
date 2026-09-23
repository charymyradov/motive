import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../cubit/home_cubit.dart';

/// Floating frosted tab bar.
class MotiveTabBar extends StatelessWidget {
  const MotiveTabBar({super.key, required this.current, required this.onSelect});

  static const height = 66.0;

  final HomeTab current;
  final ValueChanged<HomeTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(33),
        boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 40, spreadRadius: -10, offset: Offset(0, 18))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(33),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: c.bar,
              borderRadius: BorderRadius.circular(33),
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                for (final tab in HomeTab.values)
                  Expanded(
                    child: _TabButton(
                      tab: tab,
                      active: tab == current,
                      onTap: () {
                        if (tab != current) HapticFeedback.selectionClick();
                        onSelect(tab);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.tab, required this.active, required this.onTap});
  final HomeTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final color = active ? c.ink : c.ink3;
    final label = switch (tab) {
      HomeTab.feed => 'Feed',
      HomeTab.cards => 'Cards',
      HomeTab.analyze => 'Analyze',
      HomeTab.me => 'Me',
    };
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 54,
          decoration: BoxDecoration(
            color: active ? c.glass2 : Colors.transparent,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 22, child: Center(child: _TabIcon(tab: tab, active: active, color: color))),
              const SizedBox(height: 3),
              Text(label, style: AppText.sans(10.5, weight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.tab, required this.active, required this.color});
  final HomeTab tab;
  final bool active;
  final Color color;

  /// Phosphor icons: (inactive thin line, active filled).
  static (IconData, IconData) _icons(HomeTab tab) => switch (tab) {
        HomeTab.feed => (_P.cards, _P.cardsFill),
        HomeTab.cards => (_P.squaresFour, _P.squaresFourFill),
        HomeTab.analyze => (_P.magnifyingGlass, _P.magnifyingGlassFill),
        HomeTab.me => (_P.userCircle, _P.userCircleFill),
      };

  @override
  Widget build(BuildContext context) {
    final (regular, fill) = _icons(tab);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, a) => ScaleTransition(
        scale: Tween(begin: .8, end: 1.0).animate(a),
        child: FadeTransition(opacity: a, child: child),
      ),
      child: Icon(
        active ? fill : regular,
        key: ValueKey(active),
        size: 21,
        color: color,
      ),
    );
  }
}

/// Phosphor glyphs used by the tab bar (fonts bundled in assets/fonts/phosphor).
abstract final class _P {
  static const cards = IconData(0xe0f8, fontFamily: 'PhosphorRegular');
  static const cardsFill = IconData(0xe0f8, fontFamily: 'PhosphorFill');
  static const squaresFour = IconData(0xe464, fontFamily: 'PhosphorRegular');
  static const squaresFourFill = IconData(0xe464, fontFamily: 'PhosphorFill');
  static const magnifyingGlass = IconData(0xe30c, fontFamily: 'PhosphorRegular');
  static const magnifyingGlassFill = IconData(0xe30c, fontFamily: 'PhosphorFill');
  static const userCircle = IconData(0xe4c4, fontFamily: 'PhosphorRegular');
  static const userCircleFill = IconData(0xe4c4, fontFamily: 'PhosphorFill');
}
