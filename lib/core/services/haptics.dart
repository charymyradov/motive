import 'package:flutter/services.dart';

/// Named haptic patterns, so each action feels different instead of every
/// tap firing the same `selectionClick`.
///
/// Keep the timings short: patterns longer than ~200 ms read as one buzz.
abstract final class Haptics {
  /// Generic tap on a chip, tab or toggle.
  static Future<void> tap() => HapticFeedback.selectionClick();

  /// Card leaves the stack (swipe or button answer).
  static Future<void> swipe() => HapticFeedback.lightImpact();

  /// A case was answered correctly. Steps up with rarity so a legendary
  /// pull feels heavier than a common one.
  static Future<void> correct({int tier = 1}) async {
    switch (tier) {
      case 1:
        await HapticFeedback.lightImpact();
      case 2:
        await HapticFeedback.mediumImpact();
      case 3:
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 70));
        await HapticFeedback.mediumImpact();
      default:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 70));
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 110));
        await HapticFeedback.mediumImpact();
    }
  }

  /// A case was answered wrong: one hard hit, then a softer follow-up.
  static Future<void> wrong() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.mediumImpact();
  }

  /// Card reveal: the flip lands, then the burst.
  static Future<void> unlock({int tier = 1}) async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (tier >= 4) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  /// Milestones: streak kept, field mastered, level up.
  static Future<void> celebrate() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.heavyImpact();
  }

  /// Blocked action (locked card, denied permission): two short warnings.
  static Future<void> denied() async {
    await HapticFeedback.vibrate();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.vibrate();
  }
}
