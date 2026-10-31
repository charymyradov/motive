import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/answer_outcome.dart';
import '../entities/daily_drop.dart';
import '../entities/game_catalog.dart';
import '../entities/player_progress.dart';
import '../repositories/game_repository.dart';

class GetCatalog implements UseCase<GameCatalog, NoParams> {
  const GetCatalog(this._repo);
  final GameRepository _repo;

  @override
  Future<Either<Failure, GameCatalog>> call(NoParams params) => _repo.getCatalog();
}

class GetProgress implements UseCase<PlayerProgress, NoParams> {
  const GetProgress(this._repo);
  final GameRepository _repo;

  @override
  Future<Either<Failure, PlayerProgress>> call(NoParams params) => _repo.getProgress();
}

class GetTodayDrop implements UseCase<DailyDrop, GetTodayDropParams> {
  const GetTodayDrop(this._repo);
  final GameRepository _repo;

  @override
  Future<Either<Failure, DailyDrop>> call(GetTodayDropParams params) =>
      _repo.getTodayDrop(preferredFields: params.preferredFields);
}

class GetTodayDropParams extends Equatable {
  const GetTodayDropParams(this.preferredFields);
  final List<String> preferredFields;
  @override
  List<Object?> get props => [preferredFields];
}

class AnswerCase implements UseCase<AnswerOutcome, AnswerCaseParams> {
  const AnswerCase(this._repo);
  final GameRepository _repo;

  @override
  Future<Either<Failure, AnswerOutcome>> call(AnswerCaseParams params) =>
      _repo.answerCase(cardId: params.cardId, saysHolds: params.saysHolds);
}

class AnswerCaseParams extends Equatable {
  const AnswerCaseParams({required this.cardId, required this.saysHolds});
  final String cardId;
  final bool saysHolds;
  @override
  List<Object?> get props => [cardId, saysHolds];
}

class ResetProgress implements UseCase<Unit, NoParams> {
  const ResetProgress(this._repo);
  final GameRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repo.resetProgress();
}

class GetNotes implements UseCase<Map<String, String>, NoParams> {
  const GetNotes(this._repo);
  final GameRepository _repo;

  @override
  Future<Either<Failure, Map<String, String>>> call(NoParams params) => _repo.getNotes();
}

class SaveNote implements UseCase<Unit, SaveNoteParams> {
  const SaveNote(this._repo);
  final GameRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(SaveNoteParams params) =>
      _repo.saveNote(cardId: params.cardId, text: params.text);
}

class SaveNoteParams extends Equatable {
  const SaveNoteParams({required this.cardId, required this.text});
  final String cardId;
  final String text;
  @override
  List<Object?> get props => [cardId, text];
}
