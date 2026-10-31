import 'package:equatable/equatable.dart';

import 'daily_drop.dart';
import 'player_progress.dart';
import '../services/achievements.dart';
import '../services/challenges.dart';

/// Result of judging one case.
class AnswerOutcome extends Equatable {
  const AnswerOutcome({
    required this.cardId,
    required this.correct,
    required this.xpGained,
    required this.unlocked,
    required this.progress,
    required this.drop,
    this.achievements = const [],
    this.challenges = const [],
  });

  final String cardId;
  final bool correct;
  final int xpGained;

  /// True when the card was added to the collection by this answer.
  final bool unlocked;
  final PlayerProgress progress;
  final DailyDrop drop;

  /// Badges earned by this answer (already persisted in [progress]).
  final List<Achievement> achievements;

  /// Weekly challenges whose reward this answer paid out (already persisted
  /// in [progress]; [xpGained] includes their XP).
  final List<WeeklyChallenge> challenges;

  @override
  List<Object?> get props =>
      [cardId, correct, xpGained, unlocked, progress, drop, achievements, challenges];
}
