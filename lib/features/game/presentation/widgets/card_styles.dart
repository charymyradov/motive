import 'package:flutter/material.dart';

import '../../../../core/widgets/card_art.dart';
import '../../domain/entities/rarity.dart';

/// Visual identity of each rarity.
class RarityStyle {
  const RarityStyle({required this.color, required this.glow, required this.base, required this.spots});

  final Color color;
  final Color glow;
  final Color base;
  final List<GradientSpot> spots;

  static const _common = RarityStyle(
    color: Color(0xFFC3CBE0),
    glow: Color(0x73C3CBE0),
    base: Color(0xFF10121C),
    spots: [
      GradientSpot(Alignment(-.7, -1), Color(0xFF5A6784), radius: 1.2),
      GradientSpot(Alignment(1, 1), Color(0xFF2C3550), radius: .9, stop: .6),
    ],
  );
  static const _rare = RarityStyle(
    color: Color(0xFF5AA8FF),
    glow: Color(0x995AA8FF),
    base: Color(0xFF06112A),
    spots: [
      GradientSpot(Alignment(-.7, -1), Color(0xFF1F6BFF), radius: 1.2),
      GradientSpot(Alignment(1, 1), Color(0xFF00C6FF), radius: .9, stop: .6),
    ],
  );
  static const _epic = RarityStyle(
    color: Color(0xFFC77DFF),
    glow: Color(0xA6C77DFF),
    base: Color(0xFF150828),
    spots: [
      GradientSpot(Alignment(-.7, -1), Color(0xFF7B2CFF), radius: 1.2),
      GradientSpot(Alignment(1, 1), Color(0xFFFF3FB4), radius: .9, stop: .6),
    ],
  );
  static const _legendary = RarityStyle(
    color: Color(0xFFFFC857),
    glow: Color(0xB3FFC857),
    base: Color(0xFF1E0D05),
    spots: [
      GradientSpot(Alignment(-.7, -1), Color(0xFFFF8A00), radius: 1.2),
      GradientSpot(Alignment(1, 1), Color(0xFFFF3D6E), radius: .9, stop: .6),
      GradientSpot(Alignment(.2, -.2), Color(0xFFFFE27A), radius: .6, stop: .7),
    ],
  );

  static RarityStyle of(Rarity r) => switch (r) {
        Rarity.common => _common,
        Rarity.rare => _rare,
        Rarity.epic => _epic,
        Rarity.legendary => _legendary,
      };
}

abstract final class FieldStyle {
  static const _colors = {
    'rc': Color(0xFFFF7AA8),
    'ms': Color(0xFF4FE3C1),
    'mm': Color(0xFFFFA65C),
    'ng': Color(0xFFB9FF5C),
  };

  static Color color(String fieldId) => _colors[fieldId] ?? const Color(0xFFC77DFF);
}
