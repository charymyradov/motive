import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';
import 'motive_card.dart';
import 'psych_field.dart';

enum ExpertRank {
  novice('Novice'),
  apprentice('Apprentice'),
  adept('Adept'),
  expert('Expert');

  const ExpertRank(this.label);
  final String label;

  static ExpertRank forCount(int n) => n >= AppConstants.cardsPerField
      ? expert
      : n >= 4
          ? adept
          : n >= 2
              ? apprentice
              : novice;
}

/// Progress of the player in one field ("expert path").
class FieldMastery extends Equatable {
  const FieldMastery({required this.field, required this.collected, required this.cards});

  final PsychField field;
  final int collected;

  /// All cards of the field in catalog order.
  final List<MotiveCard> cards;

  int get total => cards.length;
  ExpertRank get rank => ExpertRank.forCount(collected);
  int get remaining => (AppConstants.cardsPerField - collected).clamp(0, AppConstants.cardsPerField);
  bool get mastered => remaining == 0;

  @override
  List<Object?> get props => [field, collected, cards];
}

/// Everything the player has earned so far.
class PlayerProgress extends Equatable {
  const PlayerProgress({
    this.xp = 0,
    this.collected = const {},
    this.activeDays = const {},
    this.totalAnswers = 0,
    this.correctAnswers = 0,
    this.missed = const {},
  });

  final int xp;

  /// Card id -> moment it was unlocked.
  final Map<String, DateTime> collected;

  /// Day keys on which at least one case was answered.
  final Set<String> activeDays;
  final int totalAnswers;
  final int correctAnswers;

  /// Cards answered wrong and not collected yet; they come back in later drops.
  final Set<String> missed;

  static const empty = PlayerProgress();

  bool has(String cardId) => collected.containsKey(cardId);
  int get collectedCount => collected.length;

  /// 0..100, or null before the first answer.
  int? get accuracy => totalAnswers == 0 ? null : (correctAnswers * 100 / totalAnswers).round();

  bool isActiveOn(DateTime day) => activeDays.contains(DayKey.of(day));

  /// Consecutive active days ending today, or ending yesterday if today has
  /// no answer yet (the streak is still alive until midnight).
  int streak([DateTime? now]) {
    final today = now ?? DateTime.now();
    var day = DateTime(today.year, today.month, today.day);
    if (!isActiveOn(day)) day = day.subtract(const Duration(days: 1));
    var n = 0;
    while (isActiveOn(day)) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  int countIn(String fieldId, List<MotiveCard> catalog) =>
      catalog.where((c) => c.fieldId == fieldId && has(c.id)).length;

  FieldMastery masteryOf(PsychField field, List<MotiveCard> catalog) => FieldMastery(
        field: field,
        collected: countIn(field.id, catalog),
        cards: catalog.where((c) => c.fieldId == field.id).toList(),
      );

  PlayerProgress copyWith({
    int? xp,
    Map<String, DateTime>? collected,
    Set<String>? activeDays,
    int? totalAnswers,
    int? correctAnswers,
    Set<String>? missed,
  }) {
    return PlayerProgress(
      xp: xp ?? this.xp,
      collected: collected ?? this.collected,
      activeDays: activeDays ?? this.activeDays,
      totalAnswers: totalAnswers ?? this.totalAnswers,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      missed: missed ?? this.missed,
    );
  }

  @override
  List<Object?> get props => [xp, collected, activeDays, totalAnswers, correctAnswers, missed];
}
