import 'package:equatable/equatable.dart';

import 'daily_drop.dart';
import 'player_progress.dart';

/// Result of judging one case.
class AnswerOutcome extends Equatable {
  const AnswerOutcome({
    required this.cardId,
    required this.correct,
    required this.xpGained,
    required this.unlocked,
    required this.progress,
    required this.drop,
  });

  final String cardId;
  final bool correct;
  final int xpGained;

  /// True when the card was added to the collection by this answer.
  final bool unlocked;
  final PlayerProgress progress;
  final DailyDrop drop;

  @override
  List<Object?> get props => [cardId, correct, xpGained, unlocked, progress, drop];
}
