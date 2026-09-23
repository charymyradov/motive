import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/answer_outcome.dart';
import '../../domain/entities/daily_drop.dart';
import '../../domain/entities/game_catalog.dart';
import '../../domain/entities/player_progress.dart';
import '../../domain/usecases/game_usecases.dart';

// ── Events ──────────────────────────────────────────────────────────────

sealed class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object?> get props => [];
}

/// Loads catalog, progress and today's drop.
class GameStarted extends GameEvent {
  const GameStarted(this.preferredFields);
  final List<String> preferredFields;
  @override
  List<Object?> get props => [preferredFields];
}

/// Re-checks the date (e.g. when the app comes back to the foreground) and
/// serves a new drop if a new day started.
class GameDayChecked extends GameEvent {
  const GameDayChecked(this.preferredFields);
  final List<String> preferredFields;
  @override
  List<Object?> get props => [preferredFields];
}

class CaseAnswered extends GameEvent {
  const CaseAnswered({required this.cardId, required this.saysHolds});
  final String cardId;
  final bool saysHolds;
  @override
  List<Object?> get props => [cardId, saysHolds];
}

class GameResetRequested extends GameEvent {
  const GameResetRequested(this.preferredFields);
  final List<String> preferredFields;
  @override
  List<Object?> get props => [preferredFields];
}

// ── State ───────────────────────────────────────────────────────────────

enum GameStatus { loading, ready, failure }

class GameState extends Equatable {
  const GameState({
    this.status = GameStatus.loading,
    this.catalog,
    this.progress = PlayerProgress.empty,
    this.drop,
    this.lastOutcome,
    this.outcomeId = 0,
    this.error,
  });

  final GameStatus status;
  final GameCatalog? catalog;
  final PlayerProgress progress;
  final DailyDrop? drop;

  /// Result of the most recent answer; [outcomeId] increments with each one
  /// so listeners can react exactly once.
  final AnswerOutcome? lastOutcome;
  final int outcomeId;
  final String? error;

  bool get isReady => status == GameStatus.ready && catalog != null && drop != null;

  GameState copyWith({
    GameStatus? status,
    GameCatalog? catalog,
    PlayerProgress? progress,
    DailyDrop? drop,
    AnswerOutcome? lastOutcome,
    int? outcomeId,
    String? error,
  }) {
    return GameState(
      status: status ?? this.status,
      catalog: catalog ?? this.catalog,
      progress: progress ?? this.progress,
      drop: drop ?? this.drop,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      outcomeId: outcomeId ?? this.outcomeId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, catalog, progress, drop, lastOutcome, outcomeId, error];
}

// ── Bloc ────────────────────────────────────────────────────────────────

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({
    required this._getCatalog,
    required this._getProgress,
    required this._getTodayDrop,
    required this._answerCase,
    required this._resetProgress,
  }) : super(const GameState()) {
    on<GameStarted>((e, emit) => _load(emit, e.preferredFields));
    on<GameDayChecked>(_onDayChecked);
    // Answers are processed one after another so progress writes never race.
    on<CaseAnswered>(_onAnswered, transformer: (events, mapper) => events.asyncExpand(mapper));
    on<GameResetRequested>(_onReset);
  }

  final GetCatalog _getCatalog;
  final GetProgress _getProgress;
  final GetTodayDrop _getTodayDrop;
  final AnswerCase _answerCase;
  final ResetProgress _resetProgress;

  Future<void> _load(Emitter<GameState> emit, List<String> preferred) async {
    final catalog = await _getCatalog(const NoParams());
    final progress = await _getProgress(const NoParams());
    final drop = await _getTodayDrop(GetTodayDropParams(preferred));

    final failure = [catalog, progress, drop].firstWhere((r) => r.isLeft(), orElse: () => catalog);
    if (failure.isLeft()) {
      emit(state.copyWith(status: GameStatus.failure, error: failure.getLeft().toNullable()!.message));
      return;
    }
    emit(state.copyWith(
      status: GameStatus.ready,
      catalog: catalog.toNullable(),
      progress: progress.toNullable(),
      drop: drop.toNullable(),
    ));
  }

  Future<void> _onDayChecked(GameDayChecked event, Emitter<GameState> emit) async {
    if (state.drop?.dayKey == DayKey.today()) return;
    await _load(emit, event.preferredFields);
  }

  Future<void> _onAnswered(CaseAnswered event, Emitter<GameState> emit) async {
    final result = await _answerCase(AnswerCaseParams(cardId: event.cardId, saysHolds: event.saysHolds));
    result.match(
      (f) => emit(state.copyWith(error: f.message)),
      (outcome) => emit(state.copyWith(
        progress: outcome.progress,
        drop: outcome.drop,
        lastOutcome: outcome,
        outcomeId: state.outcomeId + 1,
      )),
    );
  }

  Future<void> _onReset(GameResetRequested event, Emitter<GameState> emit) async {
    final result = await _resetProgress(const NoParams());
    if (result.isLeft()) {
      emit(state.copyWith(error: result.getLeft().toNullable()!.message));
      return;
    }
    emit(GameState(catalog: state.catalog, outcomeId: state.outcomeId));
    await _load(emit, event.preferredFields);
  }
}
