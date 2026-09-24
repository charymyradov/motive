import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/case_answer.dart';
import '../../domain/entities/motive_card.dart';
import '../../domain/entities/psych_field.dart';
import 'card_styles.dart';

/// A feed case the player judges by swiping right ("holds") or left
/// ("doesn't hold"), or with the two buttons.
class CaseCard extends StatefulWidget {
  const CaseCard({
    super.key,
    required this.card,
    required this.field,
    required this.answer,
    required this.wasReview,
    required this.onAnswer,
    required this.onRevealed,
    required this.onViewCard,
  });

  final MotiveCard card;
  final PsychField field;
  final CaseAnswer? answer;

  /// True when the card was already collected before this answer.
  final bool wasReview;
  final ValueChanged<bool> onAnswer;

  /// Called once the answer has been revealed on the card.
  final ValueChanged<bool> onRevealed;
  final VoidCallback onViewCard;

  @override
  State<CaseCard> createState() => _CaseCardState();
}

enum _Mode { idle, drag, out, back }

class _CaseCardState extends State<CaseCard> with TickerProviderStateMixin {
  static const _threshold = 90.0;
  static const _springBack = Cubic(.18, 1.3, .35, 1);
  static const _flyOut = Cubic(.55, 0, .9, .4);

  late final AnimationController _dx = AnimationController.unbounded(vsync: this);
  late final AnimationController _wiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  _Mode _mode = _Mode.idle;
  bool _waiting = false;
  Timer? _failsafe;

  static final _wiggleTween = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -10, end: 9), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 9, end: -5), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 1),
  ]);

  bool get _answered => widget.answer != null;

  @override
  void didUpdateWidget(CaseCard old) {
    super.didUpdateWidget(old);
    if (old.answer == null && widget.answer != null && _waiting) _reveal();
  }

  @override
  void dispose() {
    _failsafe?.cancel();
    _dx.dispose();
    _wiggle.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_answered || _waiting) return;
    setState(() => _mode = _Mode.drag);
    _dx.value += d.delta.dx;
  }

  void _onDragEnd(DragEndDetails d) {
    if (_answered || _waiting) return;
    final v = d.primaryVelocity ?? 0;
    if (_dx.value > _threshold || (v > 900 && _dx.value > 30)) {
      _commit(true);
    } else if (_dx.value < -_threshold || (v < -900 && _dx.value < -30)) {
      _commit(false);
    } else {
      setState(() => _mode = _Mode.back);
      _dx.animateTo(0, duration: const Duration(milliseconds: 620), curve: _springBack);
    }
  }

  Future<void> _commit(bool saysHolds) async {
    if (_answered || _waiting) return;
    HapticFeedback.lightImpact();
    GetIt.instance<SoundService>().playSwipe();
    setState(() {
      _mode = _Mode.out;
      _waiting = true;
    });
    await _dx.animateTo(saysHolds ? 480 : -480, duration: const Duration(milliseconds: 240), curve: _flyOut);
    if (!mounted) return;
    widget.onAnswer(saysHolds);
    // If the answer never arrives (storage error), bring the card back.
    _failsafe = Timer(const Duration(seconds: 2), () {
      if (mounted && _waiting && !_answered) {
        setState(() {
          _waiting = false;
          _mode = _Mode.back;
        });
        _dx.animateTo(0, duration: const Duration(milliseconds: 620), curve: _springBack);
      }
    });
  }

  Future<void> _reveal() async {
    _failsafe?.cancel();
    setState(() => _mode = _Mode.back);
    await _dx.animateTo(0, duration: const Duration(milliseconds: 620), curve: _springBack);
    if (!mounted) return;
    setState(() {
      _waiting = false;
      _mode = _Mode.idle;
    });
    final correct = widget.answer!.correct;
    if (!correct) {
      _wiggle.forward(from: 0);
      HapticFeedback.heavyImpact();
      GetIt.instance<SoundService>().playWrong();
      Future.delayed(const Duration(milliseconds: 90), HapticFeedback.mediumImpact);
    } else {
      GetIt.instance<SoundService>().playCorrect();
    }
    widget.onRevealed(correct);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final rs = RarityStyle.of(widget.card.rarity);
    final fc = FieldStyle.color(widget.field.id);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_dx, _wiggle]),
        builder: (context, child) {
          final dx = _dx.value;
          final live = _mode == _Mode.drag && !_answered;
          final yes = live ? (dx / 110).clamp(0.0, 1.0) : 0.0;
          final no = live ? (-dx / 110).clamp(0.0, 1.0) : 0.0;
          return Transform.translate(
            offset: Offset(dx + _wiggleTween.evaluate(_wiggle), 0),
            child: Transform.rotate(
              angle: dx / 22 * 3.1415926535 / 180,
              child: _Frame(rarityColor: rs.color, yes: yes, no: no, child: child!),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                  decoration: BoxDecoration(color: c.glass2, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlowDot(fc),
                      const SizedBox(width: 7),
                      Text(widget.field.name, style: AppText.sans(11.5, weight: FontWeight.w600, color: c.ink)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MonoLabel(widget.card.rarity.label.toUpperCase(), size: 9.5, color: rs.color, glow: true),
                const Spacer(),
                MonoLabel('CASE ${widget.card.number}', size: 10, weight: FontWeight.w500, spacing: .1),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.card.question, style: AppText.serif(31, color: c.ink, height: 1.02)),
            const SizedBox(height: 12),
            Text(widget.card.scenario.text, style: AppText.sans(14.5, color: c.ink2, height: 1.55)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                color: c.glass,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const MonoLabel('HYPOTHESIS', size: 9, weight: FontWeight.w500),
                      if (_answered)
                        MonoLabel(
                          widget.answer!.saidHolds ? 'YOU SAID: HOLDS' : "YOU SAID: DOESN'T",
                          size: 9,
                          weight: FontWeight.w500,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.card.scenario.hypothesis, style: AppText.sans(15.5, weight: FontWeight.w600, color: c.ink, height: 1.4)),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_answered || _waiting ? _buttons(context) : _result(context, rs.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(child: _choice("← Doesn't hold", Palette.nope, () => _commit(false))),
          const SizedBox(width: 10),
          Expanded(child: _choice('Holds →', Palette.holds, () => _commit(true))),
        ],
      ),
    );
  }

  Widget _choice(String label, Color color, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      scale: .96,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withValues(alpha: .45)),
        ),
        child: Text(label, style: AppText.sans(14, weight: FontWeight.w700, color: color)),
      ),
    );
  }

  Widget _result(BuildContext context, Color rarityColor) {
    final c = context.mc;
    final correct = widget.answer!.correct;
    final color = correct ? Palette.holds : Palette.nope;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlowDot(color, size: 7),
              const SizedBox(width: 8),
              MonoLabel(correct ? 'YOU SAW THROUGH IT' : 'IT GOT YOU', color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.card.force, style: AppText.serif(28, color: c.ink)),
          const SizedBox(height: 8),
          Text(widget.card.why, style: AppText.sans(14, color: c.ink2, height: 1.5)),
          const SizedBox(height: 14),
          if (correct)
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: widget.wasReview ? 'Already collected · ' : 'Card unlocked · ',
                      children: [
                        TextSpan(
                          text: widget.wasReview ? '+10 XP' : widget.card.rarity.label,
                          style: TextStyle(color: rarityColor),
                        ),
                      ],
                    ),
                    style: AppText.sans(12, weight: FontWeight.w600, color: c.ink2),
                  ),
                ),
                SolidButton(
                  label: 'View card',
                  onTap: widget.onViewCard,
                  height: 38,
                  fontSize: 13,
                  expand: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            )
          else
            Text(
              "Card stays locked. It'll come back around when you least expect it.",
              style: AppText.sans(12.5, color: c.ink3, height: 1.4),
            ),
        ],
      ),
    );
  }
}

/// Glass frame of the case card with the drag feedback overlays.
class _Frame extends StatelessWidget {
  const _Frame({required this.rarityColor, required this.yes, required this.no, required this.child});

  final Color rarityColor;
  final double yes;
  final double no;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 60, spreadRadius: -12, offset: const Offset(0, 24))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            color: c.glass,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: c.line),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -70,
                child: IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [rarityColor.withValues(alpha: .26), rarityColor.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
              if (yes > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: yes,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-1, -.2),
                            end: Alignment(1, .2),
                            colors: [Color(0x003EE6A0), Color(0x003EE6A0), Color(0x473EE6A0)],
                            stops: [0, .4, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (no > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: no,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(1, -.2),
                            end: Alignment(-1, .2),
                            colors: [Color(0x00FF5F7E), Color(0x00FF5F7E), Color(0x47FF5F7E)],
                            stops: [0, .4, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 18), child: child),
              if (yes > 0) Positioned(top: 22, left: 18, child: _Stamp('HOLDS', Palette.holds, -12, yes)),
              if (no > 0) Positioned(top: 22, right: 18, child: _Stamp("DOESN'T", Palette.nope, 12, no)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp(this.text, this.color, this.degrees, this.opacity);
  final String text;
  final Color color;
  final double degrees;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: degrees * 3.1415926535 / 180,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x8008070F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 2),
            ),
            child: Text(text, style: AppText.sans(18, weight: FontWeight.w800, color: color, letterSpacing: .08)),
          ),
        ),
      ),
    );
  }
}
