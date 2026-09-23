import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/card_art.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../game/domain/entities/rarity.dart';
import '../../../game/presentation/widgets/card_styles.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/arena_tile.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, pad.top + 18, 24, pad.bottom + 24),
          child: Column(
            children: [
              _Dots(step: state.step),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: const Cubic(.2, 1, .3, 1),
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (current, previous) => Stack(children: [...previous, ?current]),
                  transitionBuilder: (child, a) {
                    final incoming = child.key == ValueKey(state.step);
                    final dx = (incoming ? 1 : -1) * (state.forward ? 1 : -1) * .06;
                    return FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(state.step),
                    child: switch (state.step) {
                      0 => const _Welcome(),
                      1 => _Arenas(state: state),
                      _ => const _HowItWorks(),
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _next(BuildContext context) {
  final cubit = context.read<OnboardingCubit>();
  if (cubit.next()) context.read<SettingsBloc>().add(OnboardingFinished(cubit.state.picked));
}

class _Dots extends StatelessWidget {
  const _Dots({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < OnboardingState.steps; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: step == i ? 22 : 6,
            height: 4,
            decoration: BoxDecoration(
              color: c.ink.withValues(alpha: step == i ? 1 : .3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return LayoutBuilder(
      builder: (context, box) {
        final heroH = (box.maxHeight * .42).clamp(220.0, 330.0);
        final k = heroH / 330;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            SizedBox(
              height: heroH,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 40 * k,
                    child: Transform.translate(
                      offset: Offset(-85 * k, 0),
                      child: Transform.rotate(
                        angle: -13 * 3.14159 / 180,
                        child: _HeroCard(
                          width: 150 * k,
                          rarity: Rarity.epic,
                          label: 'EPIC',
                          title: 'Sunk Cost Fallacy',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40 * k,
                    child: Transform.translate(
                      offset: Offset(85 * k, 0),
                      child: Transform.rotate(
                        angle: 12 * 3.14159 / 180,
                        child: _HeroCard(width: 150 * k, rarity: Rarity.rare, label: 'RARE', title: 'Reciprocity'),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: _HeroCard(
                      width: 180 * k,
                      rarity: Rarity.legendary,
                      label: 'LEGENDARY',
                      title: 'Why are beginners so sure of themselves?',
                      italic: true,
                      sigil: true,
                    ),
                  ),
                ],
              ),
            ),
            const MonoLabel('MOTIVE', size: 11, spacing: .22),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: 'Something is steering you. ',
                children: [TextSpan(text: 'Learn what.', style: TextStyle(fontStyle: FontStyle.italic, color: c.ink2))],
              ),
              style: AppText.serif(44, color: c.ink, height: .98, letterSpacing: -.01),
            ),
            const SizedBox(height: 14),
            Text(
              'No theory. Real cases, one swipe at a time. Name the force behind the behavior and the card is yours.',
              style: AppText.sans(15.5, color: c.ink2, height: 1.5),
            ),
            const Spacer(),
            SolidButton(label: 'Start', glow: true, onTap: () => _next(context)),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.width,
    required this.rarity,
    required this.label,
    required this.title,
    this.italic = false,
    this.sigil = false,
  });

  final double width;
  final Rarity rarity;
  final String label;
  final String title;
  final bool italic;
  final bool sigil;

  @override
  Widget build(BuildContext context) {
    final r = RarityStyle.of(rarity);
    final s = width / 150;
    final radius = BorderRadius.circular(18 * s);
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: r.glow, blurRadius: 60 * s, spreadRadius: -6),
          BoxShadow(color: r.color, spreadRadius: 1.5),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CardArtBackground(base: r.base, spots: r.spots),
            Padding(
              padding: EdgeInsets.all(8 * s),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12 * s),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                ),
              ),
            ),
            if (sigil) Align(alignment: const Alignment(0, -.24), child: CardSigil(size: 70 * s, glow: const Color(0xE6FFF0C8), inner: false)),
            Positioned(left: 16 * s, top: 16 * s, child: Text(label, style: AppText.mono(7 * s, color: const Color(0xD9FFFFFF)))),
            Positioned(
              left: 16 * s,
              right: 16 * s,
              bottom: 16 * s,
              child: Text(title, style: AppText.serif(italic ? 17.5 * s : 20 * s, italic: italic, color: Colors.white, height: 1.05)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arenas extends StatelessWidget {
  const _Arenas({required this.state});
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 30),
              const MonoLabel('STEP 2 OF 3', size: 11, spacing: .22),
              const SizedBox(height: 10),
              Text('Where do you get played the most?', style: AppText.serif(40, color: c.ink)),
              const SizedBox(height: 12),
              Text(
                'Pick your arenas. Collect enough cards in one and you earn its title.',
                style: AppText.sans(15, color: c.ink2, height: 1.5),
              ),
              const SizedBox(height: 22),
              for (final f in state.fields) ...[
                ArenaTile(
                  field: f,
                  selected: state.picked.contains(f.id),
                  onTap: () => context.read<OnboardingCubit>().toggle(f.id),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _NavRow(label: 'Continue', enabled: state.canContinue),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const MonoLabel('STEP 3 OF 3', size: 11, spacing: .22),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(text: 'Read. Doubt. ', children: const [TextSpan(text: 'Swipe.', style: TextStyle(fontStyle: FontStyle.italic))]),
          style: AppText.serif(44, color: c.ink),
        ),
        const SizedBox(height: 12),
        Text(
          "Every case ends with a hypothesis. Swipe right if it holds, left if it doesn't. Call it right and the card is yours.",
          style: AppText.sans(15, color: c.ink2, height: 1.5),
        ),
        const Expanded(child: Center(child: _SwipeDemo())),
        const _NavRow(label: 'Enter the feed', enabled: true, glow: true),
      ],
    );
  }
}

/// A sample case card that swings right and left on a loop.
class _SwipeDemo extends StatefulWidget {
  const _SwipeDemo();

  @override
  State<_SwipeDemo> createState() => _SwipeDemoState();
}

class _SwipeDemoState extends State<_SwipeDemo> with SingleTickerProviderStateMixin {
  late final _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();

  static final _x = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 46.0).chain(CurveTween(curve: const Cubic(.45, 0, .2, 1))), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 46.0, end: 0.0).chain(CurveTween(curve: const Cubic(.45, 0, .2, 1))), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -46.0).chain(CurveTween(curve: const Cubic(.45, 0, .2, 1))), weight: 25),
    TweenSequenceItem(tween: Tween(begin: -46.0, end: 0.0).chain(CurveTween(curve: const Cubic(.45, 0, .2, 1))), weight: 15),
    TweenSequenceItem(tween: ConstantTween(0), weight: 10),
  ]);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(left: 0, child: RotatedBox(quarterTurns: 3, child: MonoLabel("DOESN'T HOLD", color: Palette.nope, spacing: .14))),
          const Positioned(right: 0, child: RotatedBox(quarterTurns: 1, child: MonoLabel('HOLDS', color: Palette.holds, spacing: .14))),
          AnimatedBuilder(
            animation: _ac,
            builder: (context, child) {
              final x = _x.evaluate(_ac);
              return Transform.translate(
                offset: Offset(x, 0),
                child: Transform.rotate(angle: x / 46 * 5 * 3.14159 / 180, child: child),
              );
            },
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.glass2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.line),
                boxShadow: [BoxShadow(color: c.shadow, blurRadius: 60, spreadRadius: -12, offset: const Offset(0, 24))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MonoLabel('MONEY MIND · CASE 18', size: 9, weight: FontWeight.w500, spacing: .14),
                  const SizedBox(height: 8),
                  Text('Why does \$9.99 feel so much cheaper than \$10?', style: AppText.serif(22, color: c.ink, height: 1.05)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.glass,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MonoLabel('HYPOTHESIS', size: 8, weight: FontWeight.w500, spacing: .14),
                        const SizedBox(height: 4),
                        Text('We read the first digit and round down.', style: AppText.sans(13, weight: FontWeight.w600, color: c.ink, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.label, required this.enabled, this.glow = false});
  final String label;
  final bool enabled;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Row(
      children: [
        Pressable(
          onTap: () => context.read<OnboardingCubit>().back(),
          child: Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.glass,
              shape: BoxShape.circle,
              border: Border.all(color: c.line),
            ),
            child: Text('‹', style: AppText.sans(22, weight: FontWeight.w600, color: c.ink)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: SolidButton(label: label, enabled: enabled, glow: glow, onTap: () => _next(context))),
      ],
    );
  }
}
