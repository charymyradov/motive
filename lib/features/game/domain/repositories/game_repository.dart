import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/answer_outcome.dart';
import '../entities/daily_drop.dart';
import '../entities/game_catalog.dart';
import '../entities/player_progress.dart';

abstract interface class GameRepository {
  Future<Either<Failure, GameCatalog>> getCatalog();

  Future<Either<Failure, PlayerProgress>> getProgress();

  /// Returns today's drop, creating a new one when the day changed.
  Future<Either<Failure, DailyDrop>> getTodayDrop({required List<String> preferredFields});

  Future<Either<Failure, AnswerOutcome>> answerCase({required String cardId, required bool saysHolds});

  /// Player-authored notes, `card id -> text`. Survives a progress reset.
  Future<Either<Failure, Map<String, String>>> getNotes();

  /// Saves (or clears, when [text] is empty) the note on one card.
  Future<Either<Failure, Unit>> saveNote({required String cardId, required String text});

  Future<Either<Failure, Unit>> resetProgress();
}
