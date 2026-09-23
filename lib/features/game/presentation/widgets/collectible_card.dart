import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/card_art.dart';
import '../../domain/entities/motive_card.dart';
import '../../domain/entities/psych_field.dart';
import 'card_styles.dart';

/// Full-size front face of a collected card (unlock + detail views).
///
/// Designed at 250 logical pixels wide; everything scales with [width].
class CollectibleCard extends StatelessWidget {
  const CollectibleCard({super.key, required this.card, required this.field, this.width = 250, this.overlay});

  final MotiveCard card;
  final PsychField field;
  final double width;

  /// Optional layer painted on top (holographic sheen in the detail view).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final s = width / 250;
    final r = RarityStyle.of(card.rarity);
    final radius = BorderRadius.circular(24 * s);

    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: r.glow, blurRadius: 90 * s, spreadRadius: -4 * s),
          BoxShadow(color: r.color, spreadRadius: 1.5),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CardArtBackground(base: r.base, spots: r.spots, foil: true),
            Padding(
              padding: EdgeInsets.all(10 * s),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(color: const Color(0x3DFFFFFF)),
                ),
              ),
            ),
            Positioned(
              left: 22 * s,
              right: 22 * s,
              top: 22 * s,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      field.name.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mono(9.5 * s, color: const Color(0xD9FFFFFF), letterSpacing: .12),
                    ),
                  ),
                  Text('NO. ${card.number}', style: AppText.mono(9.5 * s, color: const Color(0xD9FFFFFF), letterSpacing: .12)),
                ],
              ),
            ),
            Align(
              alignment: const Alignment(0, -.24),
              child: CardSigil(size: 116 * s, glow: r.glow),
            ),
            Positioned(
              left: 22 * s,
              right: 22 * s,
              bottom: 22 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(card.force, style: AppText.serif(33 * s, color: Colors.white, height: .98)),
                  SizedBox(height: 8 * s),
                  Text(
                    card.question,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.serif(14.5 * s, italic: true, color: const Color(0xD1FFFFFF), height: 1.2),
                  ),
                  SizedBox(height: 12 * s),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.rarity.label.toUpperCase(),
                          style: AppText.mono(9 * s, weight: FontWeight.w600, color: r.color, letterSpacing: .16),
                        ),
                      ),
                      for (var i = 1; i <= 4; i++)
                        Container(
                          width: 6 * s,
                          height: 6 * s,
                          margin: EdgeInsets.only(left: 5 * s),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: r.color.withValues(alpha: i <= card.rarity.tier ? 1 : .25),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

/// Back of a card, shown before the flip in the unlock animation.
class CardBack extends StatelessWidget {
  const CardBack({super.key, this.width = 250});
  final double width;

  @override
  Widget build(BuildContext context) {
    final s = width / 250;
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * s),
        gradient: const RadialGradient(
          center: Alignment(0, -.2),
          radius: .8,
          colors: [Color(0xFF2A1F55), Color(0xFF0C0A18)],
        ),
        boxShadow: [
          const BoxShadow(color: Color(0x33FFFFFF), spreadRadius: 1.5),
          BoxShadow(color: const Color(0x99000000), blurRadius: 80 * s, offset: Offset(0, 30 * s)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(10 * s),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                ),
              ),
            ),
          ),
          _ring(150 * s, const Color(0x24FFFFFF)),
          _ring(100 * s, const Color(0x33FFFFFF)),
          Text('M', style: AppText.serif(60 * s, italic: true, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _ring(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c)),
      );
}
