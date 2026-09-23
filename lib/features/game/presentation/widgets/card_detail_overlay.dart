import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/buttons.dart';
import '../bloc/game_bloc.dart';
import 'collectible_card.dart';

/// Inspect a collected card: drag on it to tilt it and catch the foil.
class CardDetailOverlay extends StatefulWidget {
  const CardDetailOverlay({super.key, required this.cardId, required this.onClose});

  final String cardId;
  final VoidCallback onClose;

  @override
  State<CardDetailOverlay> createState() => _CardDetailOverlayState();
}

class _CardDetailOverlayState extends State<CardDetailOverlay> with SingleTickerProviderStateMixin {
  /// Pointer position over the card in 0..1, (0.5, 0.5) = resting.
  late final _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  Offset _p = const Offset(.5, .5);
  Offset _from = const Offset(.5, .5);
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _settle.addListener(() {
      final t = const Cubic(.2, 1, .3, 1).transform(_settle.value);
      setState(() => _p = Offset.lerp(_from, const Offset(.5, .5), t)!);
    });
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _track(Offset local, Size size) {
    _settle.stop();
    setState(() {
      _active = true;
      _p = Offset((local.dx / size.width).clamp(0, 1), (local.dy / size.height).clamp(0, 1));
    });
  }

  void _release() {
    _from = _p;
    setState(() => _active = false);
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.select((GameBloc b) => b.state.catalog)!;
    final card = catalog.card(widget.cardId);
    final field = catalog.field(card.fieldId);
    final screen = MediaQuery.sizeOf(context);
    final w = math.min(260.0, screen.height * .34);
    final size = Size(w, w * 1.4);

    final rx = (0.5 - _p.dy) * 20 * math.pi / 180;
    final ry = (_p.dx - 0.5) * 24 * math.pi / 180;
    final lit = _active || _settle.isAnimating;
    final scale = lit ? 1.03 : 1.0;

    final sheen = Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: lit ? 1 : 0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(_p.dx * 2 - 1, _p.dy * 2 - 1),
                    radius: .9,
                    colors: const [Color(0x55FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.6 + _p.dx * 1.2, -1.6 + _p.dy * 1.2),
                    end: Alignment(1.6 + _p.dx * 1.2, 1.6 + _p.dy * 1.2),
                    colors: const [
                      Color(0x00FFFFFF),
                      Color(0x38FFFFFF),
                      Color(0x2EA0DCFF),
                      Color(0x29FFA0E6),
                      Color(0x00FFFFFF),
                    ],
                    stops: const [.3, .45, .5, .55, .7],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.onClose,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: const ColoredBox(color: Color(0xBD05040C)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {},
                    onPanDown: (d) => _track(d.localPosition, size),
                    onPanUpdate: (d) => _track(d.localPosition, size),
                    onPanEnd: (_) => _release(),
                    onPanCancel: _release,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 1 / 900)
                        ..rotateX(rx)
                        ..rotateY(ry)
                        ..scaleByDouble(scale, scale, 1, 1),
                      child: CollectibleCard(card: card, field: field, width: w, overlay: sheen),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const MonoLabel('DRAG TO TILT', color: Color(0x8CF4F2FB), spacing: .18),
                  const SizedBox(height: 12),
                  Text(
                    card.why,
                    textAlign: TextAlign.center,
                    style: AppText.sans(14.5, color: const Color(0xD1F4F2FB), height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Text('Tap anywhere to close', style: AppText.sans(13, color: const Color(0x80F4F2FB))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
