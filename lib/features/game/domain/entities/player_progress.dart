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

/// Answer counters for one calendar day, keyed by day key in
/// [PlayerProgress.daily].
///
/// Kept as a plain value object so the UI can build weekly summaries without
/// touching storage; the Hive model maps it to `[answers, correct, xp]`.
class DayStat extends Equatable {
  const DayStat({this.answers = 0, this.correct = 0, this.xp = 0});

  final int answers;
  final int correct;
  final int xp;

  static const empty = DayStat();

  bool get active => answers > 0;
  int? get accuracy => answers == 0 ? null : (correct * 100 / answers).round();

  DayStat add({required bool isCorrect, required int xp}) => DayStat(
        answers: answers + 1,
        correct: correct + (isCorrect ? 1 : 0),
        xp: this.xp + xp,
      );

  List<int> toList() => [answers, correct, xp];

  static DayStat fromList(List<int> l) =>
      DayStat(answers: l.elementAtOrNull(0) ?? 0, correct: l.elementAtOrNull(1) ?? 0, xp: l.elementAtOrNull(2) ?? 0);

  @override
  List<Object?> get props => [answers, correct, xp];
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
    this.daily = const {},
    this.unlockedAchievements = const {},
    this.claimedChallenges = const {},
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

  /// Day key -> answers/correct/xp earned that day. Older than ~90 days is
  /// pruned on write; enough for weekly and monthly summaries.
  final Map<String, DayStat> daily;

  /// Achievement id -> moment it was earned.
  final Map<String, DateTime> unlockedAchievements;

  /// Challenge instance keys (`week:2026-10-05:cards10`) already rewarded.
  final Set<String> claimedChallenges;

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

  /// Answer counters for one day, creating an empty entry when absent.
  DayStat statOn(DateTime day) => daily[DayKey.of(day)] ?? DayStat.empty;

  /// Answers recorded in the week containing [now] (Monday-start).
  WeekSummary weekOf(DateTime now) {
    final from = DayKey.startOfWeek(now);
    var answers = 0, correct = 0, xp = 0, active = 0;
    for (var i = 0; i < 7; i++) {
      final day = from.add(Duration(days: i));
      if (day.isAfter(now)) break;
      final s = statOn(day);
      answers += s.answers;
      correct += s.correct;
      xp += s.xp;
      if (s.active) active++;
    }
    final cards = [
      for (final e in collected.entries)
        if (!e.value.isBefore(from) && e.value.isBefore(now.add(const Duration(days: 1)))) e.key,
    ];
    return WeekSummary(
      from: from,
      answers: answers,
      correct: correct,
      xp: xp,
      activeDays: active,
      cardsCollected: cards.length,
      collectedIds: cards,
    );
  }

  /// Adds one answer to the day bucket and returns a new progress.
  ///
  /// Buckets older than [keepDays] are dropped so the map stays small; weekly
  /// and monthly summaries only ever read recent days.
  PlayerProgress withAnswerOn({
    required DateTime day,
    required bool correct,
    required int xp,
    int keepDays = 90,
  }) {
    final key = DayKey.of(day);
    final cutoff = DayKey.of(day.subtract(Duration(days: keepDays)));
    final next = <String, DayStat>{
      for (final e in daily.entries)
        if (e.key.compareTo(cutoff) >= 0) e.key: e.value,
      key: (daily[key] ?? DayStat.empty).add(isCorrect: correct, xp: xp),
    };
    return copyWith(daily: next);
  }

  PlayerProgress copyWith({
    int? xp,
    Map<String, DateTime>? collected,
    Set<String>? activeDays,
    int? totalAnswers,
    int? correctAnswers,
    Set<String>? missed,
    Map<String, DayStat>? daily,
    Map<String, DateTime>? unlockedAchievements,
    Set<String>? claimedChallenges,
  }) {
    return PlayerProgress(
      xp: xp ?? this.xp,
      collected: collected ?? this.collected,
      activeDays: activeDays ?? this.activeDays,
      totalAnswers: totalAnswers ?? this.totalAnswers,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      missed: missed ?? this.missed,
      daily: daily ?? this.daily,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      claimedChallenges: claimedChallenges ?? this.claimedChallenges,
    );
  }

  @override
  List<Object?> get props =>
      [xp, collected, activeDays, totalAnswers, correctAnswers, missed, daily, unlockedAchievements, claimedChallenges];
}

/// Answer activity for one calendar week (Monday-start).
class WeekSummary extends Equatable {
  const WeekSummary({
    required this.from,
    required this.answers,
    required this.correct,
    required this.xp,
    required this.activeDays,
    required this.cardsCollected,
    required this.collectedIds,
  });

  final DateTime from;
  final int answers;
  final int correct;
  final int xp;
  final int activeDays;
  final int cardsCollected;

  /// Card ids unlocked during the week, oldest first.
  final List<String> collectedIds;

  int? get accuracy => answers == 0 ? null : (correct * 100 / answers).round();

  /// Most productive arena this week, or null when nothing was collected.
  String? topField(List<MotiveCard> catalog) {
    if (collectedIds.isEmpty) return null;
    final counts = <String, int>{};
    for (final id in collectedIds) {
      final card = catalog.where((c) => c.id == id).firstOrNull;
      if (card == null) continue;
      counts[card.fieldId] = (counts[card.fieldId] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  bool get isEmpty => answers == 0 && cardsCollected == 0;

  @override
  List<Object?> get props => [from, answers, correct, xp, activeDays, cardsCollected, collectedIds];
}
