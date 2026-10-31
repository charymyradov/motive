import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/haptics.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../game/domain/services/achievements.dart';
import '../../../game/domain/services/challenges.dart';
import '../../../game/presentation/bloc/game_bloc.dart';

/// "THIS WEEK" label + the week's headline numbers.
class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final game = context.watch<GameBloc>().state;
    final catalog = game.catalog;
    if (catalog == null) return const SizedBox.shrink();
    final week = game.progress.weekOf(DateTime.now());
    final top = week.topField(catalog.cards);
    final empty = week.isEmpty;

    return Glass(
      radius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MonoLabel('THIS WEEK', spacing: .18),
              const Spacer(),
              Text(
                empty ? 'Nothing yet' : '${week.from.day}/${week.from.month} on',
                style: AppText.mono(10, color: c.ink3, letterSpacing: .1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (empty)
            Text(
              'Answer a case to start this week\'s summary.',
              style: AppText.sans(13.5, color: c.ink3, height: 1.45),
            )
          else ...[
            Row(
              children: [
                Expanded(child: _Metric(value: '${week.cardsCollected}', label: 'Cards')),
                const SizedBox(width: 8),
                Expanded(child: _Metric(value: '${week.correct}/${week.answers}', label: 'Right')),
                const SizedBox(width: 8),
                Expanded(child: _Metric(value: week.accuracy == null ? '—' : '${week.accuracy}%', label: 'Accuracy')),
                const SizedBox(width: 8),
                Expanded(child: _Metric(value: '${week.xp}', label: 'XP')),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.calendar_view_week, size: 14, color: c.ink3),
                const SizedBox(width: 6),
                Text(
                  '${week.activeDays} active day${week.activeDays == 1 ? '' : 's'}',
                  style: AppText.sans(12.5, color: c.ink2),
                ),
                if (top != null) ...[
                  const SizedBox(width: 14),
                  Icon(Icons.museum_outlined, size: 14, color: c.ink3),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${catalog.field(top).name} leads',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(12.5, color: c.ink2),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppText.serif(24, color: c.ink)),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppText.mono(9, color: c.ink3, letterSpacing: .12)),
      ],
    );
  }
}

/// The three goals of the week with progress bars.
class WeeklyChallengesCard extends StatelessWidget {
  const WeeklyChallengesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final game = context.watch<GameBloc>().state;
    if (game.catalog == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final list = Challenges.forWeek(game.progress, now);

    return Glass(
      radius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoLabel('WEEKLY GOALS', spacing: .18),
          const SizedBox(height: 6),
          Text(
            'Three goals reset every Monday. Finishing one pays XP once.',
            style: AppText.sans(12.5, color: c.ink2, height: 1.45),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < list.length; i++) ...[
            _ChallengeRow(challenge: list[i]),
            if (i != list.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({required this.challenge});
  final WeeklyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final done = challenge.isComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                challenge.title,
                style: AppText.sans(14, weight: FontWeight.w700, color: done ? Palette.holds : c.ink),
              ),
            ),
            Text(
              challenge.counter,
              style: AppText.mono(11, weight: FontWeight.w600, color: done ? Palette.holds : c.ink2, letterSpacing: 0),
            ),
            const SizedBox(width: 8),
            Text(
              '+${challenge.reward} XP',
              style: AppText.mono(10, color: done ? Palette.holds : Palette.accent, letterSpacing: .06),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(challenge.blurb, style: AppText.sans(12, color: c.ink3)),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(end: challenge.fraction),
          duration: const Duration(milliseconds: 700),
          curve: const Cubic(.2, 1, .3, 1),
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: c.line)),
                  FractionallySizedBox(
                    widthFactor: v == 0 ? 0.0001 : v,
                    child: ColoredBox(
                      color: done ? Palette.holds : Palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge wall: earned badges glow, locked ones sit dim with their goal.
class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final game = context.watch<GameBloc>().state;
    final catalog = game.catalog;
    if (catalog == null) return const SizedBox.shrink();
    final progress = game.progress;
    final earned = progress.unlockedAchievements;
    final count = Achievements.all.where((a) => earned.containsKey(a.id)).length;

    return Glass(
      radius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MonoLabel('ACHIEVEMENTS', spacing: .18),
              const Spacer(),
              Text(
                '$count/${Achievements.all.length}',
                style: AppText.mono(10, weight: FontWeight.w600, color: c.ink2, letterSpacing: .1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final a in Achievements.all)
                _Badge(
                  achievement: a,
                  unlockedAt: earned[a.id],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement, required this.unlockedAt});
  final Achievement achievement;
  final DateTime? unlockedAt;

  static const _tierColor = <AchievementTier, Color>{
    AchievementTier.bronze: Color(0xFFCD7F32),
    AchievementTier.silver: Color(0xFFB9C0CC),
    AchievementTier.gold: Color(0xFFFFC94A),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final on = unlockedAt != null;
    final color = _tierColor[achievement.tier]!;

    return Tooltip(
      message: on ? achievement.description : '${achievement.title} — ${achievement.description}',
      child: GestureDetector(
        onTap: () {
          Haptics.tap();
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(achievement.title, style: AppText.serif(26, color: c.ink)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.description, style: AppText.sans(14, color: c.ink2, height: 1.45)),
                  const SizedBox(height: 12),
                  Text(
                    on ? 'Earned ${_date(unlockedAt!)}' : 'Not earned yet.',
                    style: AppText.mono(11, color: on ? color : c.ink3, letterSpacing: .08),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Close', style: AppText.sans(14, weight: FontWeight.w700, color: c.ink)),
                ),
              ],
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? color.withValues(alpha: .18) : c.glass2,
            border: Border.all(color: on ? color : c.line, width: on ? 1.5 : 1),
            boxShadow: on ? [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 14, spreadRadius: -2)] : null,
          ),
          child: Icon(
            on ? Icons.emoji_events_rounded : Icons.lock_rounded,
            size: 18,
            color: on ? color : c.ink3,
          ),
        ),
      ),
    );
  }

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// Badge wall detail sheet, opened from the profile page.
Future<void> showAchievementsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: BlocProvider.value(
          value: context.read<GameBloc>(),
          child: const _AchievementList(),
        ),
      ),
    ),
  );
}

class _AchievementList extends StatelessWidget {
  const _AchievementList();

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final progress = context.watch<GameBloc>().state.progress;
    final earned = progress.unlockedAchievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Achievements', style: AppText.serif(32, color: c.ink)),
        const SizedBox(height: 6),
        Text(
          '${earned.length} of ${Achievements.all.length} earned. They never expire.',
          style: AppText.sans(13.5, color: c.ink2, height: 1.45),
        ),
        const SizedBox(height: 16),
        for (final a in Achievements.all) ...[
          _AchievementTile(achievement: a, unlockedAt: earned[a.id]),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.unlockedAt});
  final Achievement achievement;
  final DateTime? unlockedAt;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final on = unlockedAt != null;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? Palette.accent.withValues(alpha: .16) : c.glass2,
            border: Border.all(color: on ? Palette.accent : c.line),
          ),
          child: Icon(on ? Icons.emoji_events_rounded : Icons.lock_rounded, size: 17, color: on ? Palette.accent : c.ink3),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: AppText.sans(14, weight: FontWeight.w700, color: on ? c.ink : c.ink3),
              ),
              const SizedBox(height: 2),
              Text(achievement.description, style: AppText.sans(12, color: c.ink3, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
