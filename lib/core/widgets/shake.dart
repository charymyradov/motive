import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lets any widget request a short "screen shake" of the whole app.
///
/// Deliberately not a [ChangeNotifier]: it is shared through a
/// `RepositoryProvider`, which rejects `Listenable` values.
class ShakeController {
  final _listeners = <VoidCallback>[];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void shake({bool haptic = true}) {
    if (haptic) HapticFeedback.heavyImpact();
    for (final l in List.of(_listeners)) {
      l();
    }
  }
}

class ShakeHost extends StatefulWidget {
  const ShakeHost({super.key, required this.controller, required this.child});

  final ShakeController controller;
  final Widget child;

  @override
  State<ShakeHost> createState() => _ShakeHostState();
}

class _ShakeHostState extends State<ShakeHost> with SingleTickerProviderStateMixin {
  late final _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  static final _offset = TweenSequence<Offset>([
    TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-3, 1)), weight: 1),
    TweenSequenceItem(tween: Tween(begin: const Offset(-3, 1), end: const Offset(3, -1)), weight: 1),
    TweenSequenceItem(tween: Tween(begin: const Offset(3, -1), end: const Offset(-2, 0)), weight: 1),
    TweenSequenceItem(tween: Tween(begin: const Offset(-2, 0), end: Offset.zero), weight: 1),
  ]);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_run);
  }

  @override
  void didUpdateWidget(ShakeHost old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_run);
      widget.controller.addListener(_run);
    }
  }

  void _run() => _ac.forward(from: 0);

  @override
  void dispose() {
    widget.controller.removeListener(_run);
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, child) => Transform.translate(offset: _offset.evaluate(_ac), child: child),
      child: widget.child,
    );
  }
}
