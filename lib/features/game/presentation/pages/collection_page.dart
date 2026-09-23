import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/card_art.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../domain/entities/game_catalog.dart';
import '../../domain/entities/motive_card.dart';
import '../../domain/entities/player_progress.dart';
import '../bloc/game_bloc.dart';
import '../cubit/collection_cubit.dart';
import '../widgets/card_styles.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.bottomInset});
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final top = MediaQuery.paddingOf(context).top;
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, game) {
        final catalog = game.catalog;
        if (catalog == null) return const Center(child: CircularProgressIndicator.adaptive());
        return BlocBuilder<CollectionCubit, CollectionState>(
          builder: (context, ui) {
            final cards = catalog.cards.where((k) => ui.filter == null || k.fieldId == ui.filter).toList();
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(18, top + 16, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: Text('Collection', style: AppText.serif(40, color: c.ink))),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${game.progress.collectedCount} OF ${catalog.cards.length}',
                                style: AppText.mono(11, weight: FontWeight.w600, color: c.ink2, letterSpacing: 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Segmented(view: ui.view),
                        if (ui.view == CollectionView.cards) ...[
                          const SizedBox(height: 14),
                          _Filters(catalog: catalog, selected: ui.filter),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (ui.view == CollectionView.cards)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset + 24),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 5 / 7,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, i) => _GridTile(card: cards[i], has: game.progress.has(cards[i].id)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset + 24),
                    sliver: SliverList.separated(
                      itemCount: catalog.fields.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _PathTile(mastery: game.progress.masteryOf(catalog.fields[i], catalog.cards), progress: game.progress),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.view});
  final CollectionView view;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    Widget seg(String label, CollectionView v) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.read<CollectionCubit>().showView(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: view == v ? c.glass2 : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(label, style: AppText.sans(13, weight: FontWeight.w700, color: c.ink)),
            ),
          ),
        );
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(4),
      child: Row(children: [seg('Cards', CollectionView.cards), seg('Expert paths', CollectionView.paths)]),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.catalog, required this.selected});
  final GameCatalog catalog;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final items = <(String?, String, Color)>[
      (null, 'All', c.ink3),
      for (final f in catalog.fields) (f.id, f.short, FieldStyle.color(f.id)),
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label, color) = items[i];
          final on = selected == id;
          return GestureDetector(
            onTap: () => context.read<CollectionCubit>().setFilter(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: on ? c.glass2 : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(label, style: AppText.sans(12.5, weight: FontWeight.w600, color: on ? c.ink : c.ink2)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.card, required this.has});
  final MotiveCard card;
  final bool has;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final r = RarityStyle.of(card.rarity);
    final radius = BorderRadius.circular(14);

    final tile = has
        ? Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(color: r.glow, blurRadius: 28, spreadRadius: -8, offset: const Offset(0, 8)),
                BoxShadow(color: r.color, spreadRadius: 1),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CardArtBackground(base: r.base, spots: r.spots),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                    ),
                  ),
                  Align(alignment: const Alignment(0, -.28), child: CardSigil(size: 40, glow: r.glow, inner: false)),
                  Positioned(left: 10, top: 9, child: Text(card.number, style: AppText.mono(7.5, color: const Color(0xCCFFFFFF), letterSpacing: .1))),
                  Positioned(
                    left: 10,
                    right: 8,
                    bottom: 10,
                    child: Text(card.force, maxLines: 3, style: AppText.serif(15, color: Colors.white)),
                  ),
                ],
              ),
            ),
          )
        : ClipRRect(
            borderRadius: radius,
            child: Container(
              decoration: BoxDecoration(
                color: c.glass,
                borderRadius: radius,
                border: Border.all(color: c.line),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: .6,
                    child: CustomPaint(painter: StripesPainter(color: c.line, angle: 135, width: 1, period: 8)),
                  ),
                  Positioned(left: 10, top: 9, child: Text(card.number, style: AppText.mono(7.5, color: c.ink3, letterSpacing: .1))),
                  Align(alignment: const Alignment(0, -.35), child: Text('?', style: AppText.serif(34, color: c.ink3))),
                  Positioned(
                    left: 9,
                    right: 9,
                    bottom: 10,
                    child: Text(
                      card.question,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(9.5, color: c.ink2, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          );

    return Pressable(
      scale: .95,
      onTap: () {
        if (has) {
          context.read<HomeCubit>().showDetail(card.id);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Still locked. Solve its case in the feed to collect it.')));
        }
      },
      child: tile,
    );
  }
}

class _PathTile extends StatelessWidget {
  const _PathTile({required this.mastery, required this.progress});
  final FieldMastery mastery;
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final fc = FieldStyle.color(mastery.field.id);
    final n = mastery.collected;
    final per = AppConstants.cardsPerField;
    final rankLabel = mastery.rank.label.toUpperCase() + (mastery.mastered ? '' : ' · ${mastery.field.short.toUpperCase()}');
    final next = mastery.mastered
        ? 'Title earned. You are a ${mastery.field.name}.'
        : '${mastery.remaining} more card${mastery.remaining == 1 ? '' : 's'} to become a ${mastery.field.name}';

    return Glass(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -78,
            left: -58,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [fc.withValues(alpha: .22), fc.withValues(alpha: 0)]),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: n / per),
                    duration: const Duration(milliseconds: 900),
                    curve: const Cubic(.2, 1, .3, 1),
                    builder: (context, v, _) => Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          transform: const GradientRotation(-math.pi / 2),
                          colors: [fc, fc, c.line, c.line],
                          stops: [0, v, v, 1],
                        ),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text.rich(
                          TextSpan(
                            text: '$n',
                            children: [
                              TextSpan(text: '/$per', style: AppText.sans(12, weight: FontWeight.w500, color: c.ink3)),
                            ],
                          ),
                          style: AppText.sans(16, weight: FontWeight.w700, color: c.ink),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MonoLabel(rankLabel, size: 9.5),
                        const SizedBox(height: 3),
                        Text(mastery.field.name, style: AppText.serif(25, color: c.ink)),
                        const SizedBox(height: 5),
                        Text(next, style: AppText.sans(12.5, color: c.ink2)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final (i, card) in mastery.cards.indexed) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: progress.has(card.id) ? RarityStyle.of(card.rarity).color : c.line,
                          boxShadow: progress.has(card.id)
                              ? [BoxShadow(color: RarityStyle.of(card.rarity).glow, blurRadius: 8)]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
