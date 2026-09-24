import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shake.dart';
import '../../domain/entities/game_catalog.dart';
import '../../domain/entities/player_progress.dart';
import '../bloc/game_bloc.dart';
import 'card_styles.dart';
import 'celebration.dart';
import 'collectible_card.dart';

/// Full-screen reveal of a newly unlocked card: it flies in face down, flips,
/// bursts into confetti and shows the XP and field progress.
class UnlockOverlay extends StatefulWidget {
  const UnlockOverlay({super.key, required this.cardId, required this.onClose, required this.onOpenCollection});

  final String cardId;
  final VoidCallback onClose;
  final VoidCallback onOpenCollection;

  @override
  State<UnlockOverlay> createState() => _UnlockOverlayState();
}

class _UnlockOverlayState extends State<UnlockOverlay> with TickerProviderStateMixin {
  static const _springy = Cubic(.2, .9, .25, 1.12);

  late final _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  late final _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  final _timers = <Timer>[];
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    final sound = GetIt.instance<SoundService>();
    _timers
      ..add(Timer(const Duration(milliseconds: 40), () {
        if (!mounted) return;
        setState(() => _phase = 1);
        _enter.forward();
        sound.playUnlock();
      }))
      ..add(Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _phase = 2);
        _flip.forward();
        sound.playFlip();
        context.read<ShakeController>().shake();
      }))
      ..add(Timer(const Duration(milliseconds: 1250), () {
        if (mounted) {
          setState(() => _phase = 3);
          sound.playConfetti();
        }
      }));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _enter.dispose();
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameBloc>().state;
    final GameCatalog catalog = game.catalog!;
    final card = catalog.card(widget.cardId);
    final field = catalog.field(card.fieldId);
    final r = RarityStyle.of(card.rarity);
    final fc = FieldStyle.color(field.id);
    final PlayerProgress progress = game.progress;
    final n = progress.countIn(field.id, catalog.cards);
    final per = AppConstants.cardsPerField;
    final screen = MediaQuery.sizeOf(context);
    final cardW = math.min(250.0, screen.height * .3);

    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: const ColoredBox(color: Color(0xB805040C)),
        ),
        Align(
          alignment: const Alignment(0, -.12),
          child: AnimatedOpacity(
            opacity: _phase >= 2 ? 1 : 0,
            duration: const Duration(milliseconds: 800),
            child: OverflowBox(maxWidth: 760, maxHeight: 760, child: SpinningRays(color: r.color)),
          ),
        ),
        if (_phase >= 2)
          Align(
            alignment: const Alignment(0, -.12),
            child: ConfettiBurst(colors: [r.color, Colors.white, fc, r.color]),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  opacity: _phase >= 2 ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'NEW CARD · ${card.rarity.label.toUpperCase()}',
                    style: AppText.mono(
                      11,
                      weight: FontWeight.w600,
                      color: r.color,
                      letterSpacing: .22,
                      shadows: [Shadow(color: r.color, blurRadius: 16)],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: Listenable.merge([_enter, _flip]),
                  builder: (context, _) {
                    final e = _springy.transform(_enter.value);
                    final f = _springy.transform(_flip.value);
                    final scale = .5 + .5 * e;
                    final dy = 60 * (1 - e);
                    final angle = math.pi * (1 - f); // 180° -> 0°
                    final showBack = angle.abs() > math.pi / 2;
                    return Opacity(
                      opacity: _phase == 0 ? 0 : 1,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 1 / 1200)
                          ..translateByDouble(0, dy, 0, 1)
                          ..scaleByDouble(scale, scale, 1, 1)
                          ..rotateY(angle),
                        child: showBack
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: CardBack(width: cardW),
                              )
                            : CollectibleCard(card: card, field: field, width: cardW),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                AnimatedSlide(
                  offset: _phase >= 3 ? Offset.zero : const Offset(0, .1),
                  duration: const Duration(milliseconds: 600),
                  curve: const Cubic(.2, 1, .3, 1),
                  child: AnimatedOpacity(
                    opacity: _phase >= 3 ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: IgnorePointer(
                      ignoring: _phase < 3,
                      child: Column(
                        children: [
                          Text('+${card.rarity.xp} XP', style: AppText.serif(30, color: Palette.overlayInk)),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0x12FFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(field.name, style: AppText.sans(12.5, weight: FontWeight.w600, color: Palette.overlayInk)),
                                    Text('$n of $per', style: AppText.sans(12.5, weight: FontWeight.w600, color: const Color(0xB3F4F2FB))),
                                  ],
                                ),
                                const SizedBox(height: 9),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Container(
                                    height: 5,
                                    color: const Color(0x1FFFFFFF),
                                    alignment: Alignment.centerLeft,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(
                                        begin: (n - 1).clamp(0, per) / per,
                                        end: _phase >= 3 ? math.min(n, per) / per : (n - 1).clamp(0, per) / per,
                                      ),
                                      duration: const Duration(milliseconds: 1000),
                                      curve: const Interval(.25, 1, curve: Cubic(.2, 1, .3, 1)),
                                      builder: (context, v, _) => FractionallySizedBox(
                                        widthFactor: v,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: fc,
                                            borderRadius: BorderRadius.circular(3),
                                            boxShadow: [BoxShadow(color: fc, blurRadius: 10)],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  n >= per
                                      ? "You're now a ${field.name}."
                                      : '${per - n} more to become a ${field.name}',
                                  style: AppText.sans(12, color: const Color(0x99F4F2FB)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 10,
                                child: _OverlayButton(label: 'Collection', filled: false, onTap: widget.onOpenCollection),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 14,
                                child: _OverlayButton(label: 'Keep scrolling', filled: true, onTap: widget.onClose),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: true,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? Palette.overlayInk : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: filled ? null : Border.all(color: const Color(0x2EFFFFFF)),
        ),
        child: Text(
          label,
          style: AppText.sans(14, weight: FontWeight.w700, color: filled ? const Color(0xFF0B0A14) : Palette.overlayInk),
        ),
      ),
    );
  }
}
