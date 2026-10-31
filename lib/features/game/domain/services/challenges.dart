import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_utils.dart';
import '../entities/player_progress.dart';

/// A weekly goal. Three of these run every week (Monday-start); progress is
/// derived from [WeekSummary], so nothing extra has to be tracked per answer.
/// Completing one pays out XP exactly once, guarded by
/// [PlayerProgress.claimedChallenges].
class WeeklyChallenge extends Equatable {
  const WeeklyChallenge({
    required this.id,
    required this.title,
    required this.blurb,
    required this.target,
    required this.unit,
    required this.reward,
    required this.current,
  });

  final String id;
  final String title;
  final String blurb;
  final int target;

  /// What one unit means, shown next to the counter (e.g. "CARDS").
  final String unit;
  final int reward;

  /// How far along the player is right now.
  final int current;

  int get capped => current > target ? target : current;
  double get fraction => target == 0 ? 0 : (capped / target).clamp(0.0, 1.0);
  bool get isComplete => current >= target;
  String get counter => '$capped/$target';

  @override
  List<Object?> get props => [id, title, blurb, target, unit, reward, current];
}

/// This week's challenges, evaluated against live progress.
abstract final class Challenges {
  static const int cardTarget = 10;
  static const int correctTarget = 25;
  static const int activeTarget = 5;

  static const int cardReward = 150;
  static const int correctReward = 200;
  static const int activeReward = 120;

  /// The three goals for the week containing [now].
  static List<WeeklyChallenge> forWeek(PlayerProgress progress, DateTime now) {
    final week = progress.weekOf(now);
    final key = _weekKey(now);

    return [
      WeeklyChallenge(
        id: '$key:cards',
        title: 'Card Hunter',
        blurb: 'Collect $cardTarget cards this week.',
        target: cardTarget,
        unit: 'CARDS',
        reward: cardReward,
        current: week.cardsCollected,
      ),
      WeeklyChallenge(
        id: '$key:correct',
        title: 'Sharp Instinct',
        blurb: 'Answer $correctTarget cases correctly this week.',
        target: correctTarget,
        unit: 'RIGHT',
        reward: correctReward,
        current: week.correct,
      ),
      WeeklyChallenge(
        id: '$key:active',
        title: 'Show Up',
        blurb: 'Play on $activeTarget different days this week.',
        target: activeTarget,
        unit: 'DAYS',
        reward: activeReward,
        current: week.activeDays,
      ),
    ];
  }

  /// Challenges that are finished but whose reward has not been paid yet.
  static List<WeeklyChallenge> claimable(PlayerProgress progress, DateTime now) =>
      forWeek(progress, now)
          .where((c) => c.isComplete && !progress.claimedChallenges.contains(c.id))
          .toList();

  static String _weekKey(DateTime now) => DayKey.weekOf(now);
}
