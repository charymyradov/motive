import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/dashed_border.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../bloc/game_bloc.dart';
import '../widgets/case_card.dart';
import '../widgets/stat_pills.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key, required this.bottomInset});

  /// Space covered by the floating tab bar.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final headerHeight = top + 98;

    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state.status == GameStatus.failure) {
          return _Failure(message: state.error ?? 'Something went wrong.');
        }
        if (!state.isReady) return const Center(child: CircularProgressIndicator.adaptive());

        final catalog = state.catalog!;
        final drop = state.drop!;

        return Stack(
          children: [
            ListView.builder(
              padding: EdgeInsets.only(top: headerHeight + 18, bottom: bottomInset + 20),
              itemCount: drop.caseIds.length + 1,
              itemBuilder: (context, i) {
                if (i == drop.caseIds.length) return _DropFooter(complete: drop.isComplete, left: drop.total - drop.answered);
                final id = drop.caseIds[i];
                final card = catalog.card(id);
                final answer = drop.answerFor(id);
                final collectedAt = state.progress.collected[id];
                final wasReview = answer != null &&
                    collectedAt != null &&
                    collectedAt.isBefore(answer.answeredAt.subtract(const Duration(seconds: 1)));
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                  child: CaseCard(
                    key: ValueKey('${drop.dayKey}-$id'),
                    card: card,
                    field: catalog.field(card.fieldId),
                    answer: answer,
                    wasReview: wasReview,
                    onAnswer: (holds) => context.read<GameBloc>().add(CaseAnswered(cardId: id, saysHolds: holds)),
                    onRevealed: (correct) {
                      final outcome = context.read<GameBloc>().state.lastOutcome;
                      if (correct && outcome != null && outcome.cardId == id && outcome.unlocked) {
                        context.read<HomeCubit>().showUnlock(id);
                      }
                    },
                    onViewCard: () => context.read<HomeCubit>().showDetail(id),
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _FeedHeader(
                topPadding: top,
                streak: state.progress.streak(),
                xp: state.progress.xp,
                done: drop.answered,
                total: drop.total,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.topPadding,
    required this.streak,
    required this.xp,
    required this.done,
    required this.total,
  });

  final double topPadding;
  final int streak;
  final int xp;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 12),
          decoration: BoxDecoration(
            color: c.bar,
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Motive',
                      children: [
                        TextSpan(text: '.', style: AppText.serif(32, italic: true, color: Palette.accent)),
                      ],
                    ),
                    style: AppText.serif(32, color: c.ink, letterSpacing: -.01),
                  ),
                  const Spacer(),
                  StatPill(icon: FlameIcon(active: streak > 0), value: '$streak'),
                  const SizedBox(width: 8),
                  StatPill(icon: const XpIcon(), value: xp.grouped),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const MonoLabel("TODAY'S DROP", weight: FontWeight.w500, spacing: .14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Positioned.fill(child: ColoredBox(color: c.line)),
                            TweenAnimationBuilder<double>(
                              tween: Tween(end: total == 0 ? 0 : done / total),
                              duration: const Duration(milliseconds: 600),
                              curve: const Cubic(.2, 1, .3, 1),
                              builder: (context, v, _) => FractionallySizedBox(
                                widthFactor: v,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: const LinearGradient(colors: [Palette.xpA, Palette.xpB]),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$done/$total', style: AppText.mono(10, weight: FontWeight.w600, color: c.ink2, letterSpacing: 0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropFooter extends StatelessWidget {
  const _DropFooter({required this.complete, required this.left});
  final bool complete;
  final int left;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final remind = context.select((SettingsBloc b) => b.state.settings.reminderEnabled);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: DashedBorder(
        color: c.line,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          child: Column(
            children: [
              Text(
                complete ? "That's today's drop." : '$left case${left == 1 ? '' : 's'} to go.',
                textAlign: TextAlign.center,
                style: AppText.serif(28, color: c.ink, height: 1.05),
              ),
              const SizedBox(height: 8),
              Text(
                complete
                    ? 'New cases land tomorrow${remind ? ' at 8:00' : ''}. Until then, turn it on the people talking at you.'
                    : "Swipe right if the hypothesis holds, left if it doesn't. Call it right and the card is yours.",
                textAlign: TextAlign.center,
                style: AppText.sans(14, color: c.ink2, height: 1.5),
              ),
              if (complete) ...[
                const SizedBox(height: 16),
                GhostButton(
                  label: 'Analyze a post',
                  onTap: () => context.read<HomeCubit>().selectTab(HomeTab.analyze),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('The feed got stuck.', style: AppText.serif(30, color: c.ink)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: AppText.sans(14, color: c.ink2)),
            const SizedBox(height: 18),
            GhostButton(
              label: 'Try again',
              onTap: () {
                final picked = context.read<SettingsBloc>().state.settings.pickedFields;
                context.read<GameBloc>().add(GameStarted(picked));
              },
            ),
          ],
        ),
      ),
    );
  }
}
