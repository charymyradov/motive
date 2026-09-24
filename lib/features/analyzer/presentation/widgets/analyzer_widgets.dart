import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/analysis.dart';

/// Animated scan line shown while a post is being analyzed.
class ScannerPanel extends StatefulWidget {
  const ScannerPanel({super.key});

  @override
  State<ScannerPanel> createState() => _ScannerPanelState();
}

class _ScannerPanelState extends State<ScannerPanel> with SingleTickerProviderStateMixin {
  late final _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void initState() {
    super.initState();
    GetIt.instance<SoundService>().playScanStart();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Glass(
      radius: 26,
      child: SizedBox(
        height: 160,
        child: AnimatedBuilder(
          animation: _ac,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_ac.value);
            final opacity = t < .15 ? t / .15 : t > .85 ? (1 - t) / .15 : 1.0;
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: -10 + 160 * t,
                  child: Opacity(
                    opacity: opacity.clamp(0, 1),
                    child: Container(
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0x00C77DFF), Palette.accent, Palette.xpB, Color(0x0046D4FF)]),
                        boxShadow: [BoxShadow(color: Color(0x99A078FF), blurRadius: 24, spreadRadius: 4)],
                      ),
                    ),
                  ),
                ),
                Center(child: MonoLabel('SCANNING FOR PRESSURE TACTICS', size: 11, color: c.ink2)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Builder(builder: (context) {
                          final phase = ((_ac.value * 1.6 / 1.0) - i * .15) % 1.0;
                          final k = (1 - (phase - .5).abs() * 2).clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: .8 + .2 * k,
                            child: Opacity(
                              opacity: .25 + .75 * k,
                              child: Container(width: 6, height: 6, decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle)),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Pressure score + summary + one tile per technique.
class AnalysisResultView extends StatelessWidget {
  const AnalysisResultView({super.key, required this.analysis});
  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          radius: 26,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: analysis.pressure.toDouble()),
                    duration: const Duration(milliseconds: 900),
                    curve: const Cubic(.2, 1, .3, 1),
                    builder: (context, v, _) => Text('${v.round()}', style: AppText.serif(64, color: c.ink, height: .85)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MonoLabel('PRESSURE INDEX', size: 9.5),
                          const SizedBox(height: 3),
                          Text(analysis.label, style: AppText.sans(15, weight: FontWeight.w700, color: c.ink)),
                        ],
                      ),
                    ),
                  ),
                  _SourceBadge(source: analysis.source),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 6,
                  color: c.line,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: analysis.pressure / 100),
                    duration: const Duration(milliseconds: 1000),
                    curve: const Cubic(.2, 1, .3, 1),
                    builder: (context, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(colors: [Palette.holds, Palette.warn, Palette.nope]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(analysis.summary, style: AppText.sans(14, color: c.ink2, height: 1.5)),
            ],
          ),
        ),
        for (final t in analysis.techniques) ...[
          const SizedBox(height: 10),
          _TechniqueTile(technique: t),
        ],
        if (analysis.techniques.isEmpty) ...[
          const SizedBox(height: 10),
          Glass(
            radius: 22,
            padding: const EdgeInsets.all(18),
            child: Text(
              'No levers found. Still, ask who benefits if you believe it.',
              style: AppText.sans(13.5, color: c.ink2, height: 1.45),
            ),
          ),
        ],
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final AnalysisSource source;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final claude = source == AnalysisSource.claude;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: c.glass2, borderRadius: BorderRadius.circular(10)),
      child: MonoLabel(claude ? 'CLAUDE' : 'OFFLINE', size: 8.5, color: claude ? Palette.accent : c.ink3),
    );
  }
}

class _TechniqueTile extends StatelessWidget {
  const _TechniqueTile({required this.technique});
  final Technique technique;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final level = technique.intensity;
    final color = level >= 3
        ? Palette.nope
        : level == 2
            ? Palette.warn
            : Palette.holds;
    return Glass(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(technique.name, style: AppText.serif(23, color: c.ink))),
              for (var i = 1; i <= 3; i++)
                Container(
                  width: 14,
                  height: 5,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: i <= level ? color : c.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
          if (technique.quote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: c.line, width: 2))),
              child: Text(
                '“${technique.quote}”',
                style: AppText.sans(13, color: c.ink2, height: 1.45, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(technique.how, style: AppText.sans(13.5, color: c.ink, height: 1.45)),
        ],
      ),
    );
  }
}
