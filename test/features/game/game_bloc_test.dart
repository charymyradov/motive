import 'package:flutter_test/flutter_test.dart';
import 'package:motive/features/game/data/datasources/card_catalog_datasource.dart';
import 'package:motive/features/game/data/datasources/game_local_datasource.dart';
import 'package:motive/features/game/data/models/game_models.dart';
import 'package:motive/features/game/data/repositories/game_repository_impl.dart';
import 'package:motive/features/game/domain/usecases/game_usecases.dart';
import 'package:motive/features/game/presentation/bloc/game_bloc.dart';

class _MemoryGameStore implements GameLocalDataSource {
  ProgressModel? progress;
  DailyDropModel? drop;

  @override
  ProgressModel? getProgress() => progress;
  @override
  Future<void> saveProgress(ProgressModel p) async => progress = p;
  @override
  DailyDropModel? getDrop() => drop;
  @override
  Future<void> saveDrop(DailyDropModel d) async => drop = d;
  @override
  Future<void> clear() async {
    progress = null;
    drop = null;
  }
}

void main() {
  late GameBloc bloc;

  setUp(() {
    final repo = GameRepositoryImpl(catalog: const BundledCardCatalogDataSource(), local: _MemoryGameStore());
    bloc = GameBloc(
      getCatalog: GetCatalog(repo),
      getProgress: GetProgress(repo),
      getTodayDrop: GetTodayDrop(repo),
      answerCase: AnswerCase(repo),
      resetProgress: ResetProgress(repo),
    );
  });

  tearDown(() => bloc.close());

  test('loads the catalog and today\'s drop', () async {
    bloc.add(const GameStarted(['ms']));
    final state = await bloc.stream.firstWhere((s) => s.isReady);
    expect(state.catalog!.cards, hasLength(24));
    expect(state.drop!.caseIds, hasLength(8));
  });

  test('answering emits an outcome and updates progress', () async {
    bloc.add(const GameStarted(['ms']));
    final ready = await bloc.stream.firstWhere((s) => s.isReady);
    final card = ready.catalog!.card(ready.drop!.caseIds.first);

    bloc.add(CaseAnswered(cardId: card.id, saysHolds: card.scenario.holds));
    final after = await bloc.stream.firstWhere((s) => s.outcomeId == 1);

    expect(after.lastOutcome!.unlocked, isTrue);
    expect(after.progress.xp, card.rarity.xp);
    expect(after.drop!.answered, 1);
  });

  test('reset wipes progress', () async {
    bloc.add(const GameStarted(['ms']));
    final ready = await bloc.stream.firstWhere((s) => s.isReady);
    final card = ready.catalog!.card(ready.drop!.caseIds.first);
    bloc.add(CaseAnswered(cardId: card.id, saysHolds: card.scenario.holds));
    await bloc.stream.firstWhere((s) => s.outcomeId == 1);

    bloc.add(const GameResetRequested(['ms']));
    final reset = await bloc.stream.firstWhere((s) => s.isReady && s.progress.xp == 0);
    expect(reset.progress.collectedCount, 0);
    expect(reset.drop!.answered, 0);
  });
}
