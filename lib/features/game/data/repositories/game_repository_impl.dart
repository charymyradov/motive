import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/answer_outcome.dart';
import '../../domain/entities/case_answer.dart';
import '../../domain/entities/daily_drop.dart';
import '../../domain/entities/game_catalog.dart';
import '../../domain/entities/player_progress.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/achievements.dart';
import '../../domain/services/challenges.dart';
import '../../domain/services/drop_planner.dart';
import '../datasources/card_catalog_datasource.dart';
import '../datasources/game_local_datasource.dart';
import '../models/game_models.dart';

class GameRepositoryImpl implements GameRepository {
  GameRepositoryImpl({
    required this._catalog,
    required this._local,
    this._planner = const DropPlanner(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final CardCatalogDataSource _catalog;
  final GameLocalDataSource _local;
  final DropPlanner _planner;
  final DateTime Function() _clock;

  PlayerProgress _progress() => _local.getProgress()?.toEntity() ?? PlayerProgress.empty;

  @override
  Future<Either<Failure, GameCatalog>> getCatalog() async => Right(_catalog.load());

  @override
  Future<Either<Failure, PlayerProgress>> getProgress() async {
    try {
      // Badges are derived, so players who already qualified before a new
      // badge shipped get it on the next load without replaying history.
      final progress = _progress();
      final (updated, _) = Achievements.evaluate(progress, _catalog.load());
      if (!identical(updated, progress)) {
        await _local.saveProgress(ProgressModel.fromEntity(updated));
        return Right(updated);
      }
      return Right(progress);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, DailyDrop>> getTodayDrop({required List<String> preferredFields}) async {
    try {
      final today = DayKey.today(_clock());
      final stored = _local.getDrop()?.toEntity();
      if (stored != null && stored.dayKey == today && stored.caseIds.isNotEmpty) return Right(stored);

      final catalog = _catalog.load();
      final ids = _planner.plan(
        catalog: catalog,
        progress: _progress(),
        preferredFields: preferredFields,
        dayKey: today,
      );
      final drop = DailyDrop(dayKey: today, caseIds: ids);
      await _local.saveDrop(DailyDropModel.fromEntity(drop));
      return Right(drop);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AnswerOutcome>> answerCase({required String cardId, required bool saysHolds}) async {
    try {
      final catalog = _catalog.load();
      final card = catalog.cardOrNull(cardId);
      if (card == null) return const Left(ValidationFailure('Unknown card.'));

      final drop = _local.getDrop()?.toEntity();
      if (drop == null || !drop.caseIds.contains(cardId)) {
        return const Left(ValidationFailure("This case isn't part of today's drop."));
      }
      if (drop.answerFor(cardId) != null) return const Left(ValidationFailure('Already answered.'));

      final now = _clock();
      final progress = _progress();
      final correct = saysHolds == card.scenario.holds;
      final alreadyCollected = progress.has(cardId);
      final unlocked = correct && !alreadyCollected;
      final xp = !correct
          ? 0
          : alreadyCollected
              ? AppConstants.reviewXp
              : card.rarity.xp;

      final missed = {...progress.missed};
      if (correct) {
        missed.remove(cardId);
      } else if (!alreadyCollected) {
        missed.add(cardId);
      }

      var newProgress = progress.copyWith(
        xp: progress.xp + xp,
        collected: unlocked ? {...progress.collected, cardId: now} : progress.collected,
        activeDays: {...progress.activeDays, DayKey.of(now)},
        totalAnswers: progress.totalAnswers + 1,
        correctAnswers: progress.correctAnswers + (correct ? 1 : 0),
        missed: missed,
      ).withAnswerOn(day: now, correct: correct, xp: xp);

      // Badges first, then weekly goals — the challenge reward can itself
      // unlock a badge, so evaluation order matters.
      final (withBadges, badges) = Achievements.evaluate(newProgress, catalog);
      newProgress = withBadges;
      final newBadges = [...badges];

      var bonusXp = 0;
      final claimed = <WeeklyChallenge>[];
      for (final c in Challenges.claimable(newProgress, now)) {
        bonusXp += c.reward;
        claimed.add(c);
      }
      if (claimed.isNotEmpty) {
        newProgress = newProgress.copyWith(
          xp: newProgress.xp + bonusXp,
          claimedChallenges: {...newProgress.claimedChallenges, for (final c in claimed) c.id},
        );
        // Paying out XP may itself complete a badge (e.g. XP milestones).
        final (afterPayout, moreBadges) = Achievements.evaluate(newProgress, catalog);
        newProgress = afterPayout;
        newBadges.addAll(moreBadges);
      }

      final newDrop = drop.withAnswer(
        CaseAnswer(cardId: cardId, saidHolds: saysHolds, correct: correct, answeredAt: now),
      );

      await _local.saveProgress(ProgressModel.fromEntity(newProgress));
      await _local.saveDrop(DailyDropModel.fromEntity(newDrop));

      return Right(AnswerOutcome(
        cardId: cardId,
        correct: correct,
        xpGained: xp + bonusXp,
        unlocked: unlocked,
        progress: newProgress,
        drop: newDrop,
        achievements: newBadges,
        challenges: claimed,
      ));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> getNotes() async {
    try {
      return Right(_local.getNotes());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveNote({required String cardId, required String text}) async {
    try {
      await _local.saveNote(cardId, text);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetProgress() async {
    try {
      await _local.clear();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
