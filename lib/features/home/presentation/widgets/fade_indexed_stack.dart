import 'package:flutter/material.dart';

/// [IndexedStack] that keeps every tab alive (scroll positions survive) and
/// fades + slides the newly selected tab in.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late final _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 380), value: 1);
  late final _curve = CurvedAnimation(parent: _ac, curve: const Cubic(.2, 1, .3, 1));

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _ac.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      sizing: StackFit.expand,
      children: [
        // The wrapper structure is identical for every child so switching tabs
        // never rebuilds (and resets) a tab's element tree.
        for (var i = 0; i < widget.children.length; i++)
          TickerMode(
            enabled: i == widget.index,
            child: FadeTransition(
              opacity: i == widget.index ? _curve : kAlwaysCompleteAnimation,
              child: SlideTransition(
                position: i == widget.index
                    ? Tween(begin: const Offset(0, .017), end: Offset.zero).animate(_curve)
                    : const AlwaysStoppedAnimation(Offset.zero),
                child: widget.children[i],
              ),
            ),
          ),
      ],
    );
  }
}
