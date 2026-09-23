import 'package:flutter_test/flutter_test.dart';
import 'package:motive/core/error/failures.dart';
import 'package:motive/features/game/data/datasources/card_catalog_datasource.dart';
import 'package:motive/features/game/data/datasources/game_local_datasource.dart';
import 'package:motive/features/game/data/models/game_models.dart';
import 'package:motive/features/game/data/repositories/game_repository_impl.dart';

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
  const catalogSource = BundledCardCatalogDataSource();
  final catalog = catalogSource.load();
  late _MemoryGameStore store;
  late DateTime now;
  late GameRepositoryImpl repo;

  setUp(() {
    store = _MemoryGameStore();
    now = DateTime(2026, 9, 23, 10);
    repo = GameRepositoryImpl(catalog: catalogSource, local: store, clock: () => now);
  });

  test('creates one drop per day and keeps it for the rest of the day', () async {
    final a = (await repo.getTodayDrop(preferredFields: const ['mm'])).toNullable()!;
    now = now.add(const Duration(hours: 5));
    final b = (await repo.getTodayDrop(preferredFields: const ['ng'])).toNullable()!;
    expect(b.caseIds, a.caseIds);

    now = now.add(const Duration(days: 1));
    final c = (await repo.getTodayDrop(preferredFields: const ['mm'])).toNullable()!;
    expect(c.dayKey, isNot(a.dayKey));
  });

  test('a correct answer unlocks the card and grants rarity XP', () async {
    final drop = (await repo.getTodayDrop(preferredFields: const ['mm'])).toNullable()!;
    final card = catalog.card(drop.caseIds.first);

    final outcome = (await repo.answerCase(cardId: card.id, saysHolds: card.scenario.holds)).toNullable()!;

    expect(outcome.correct, isTrue);
    expect(outcome.unlocked, isTrue);
    expect(outcome.xpGained, card.rarity.xp);
    expect(outcome.progress.has(card.id), isTrue);
    expect(outcome.progress.streak(now), 1);
    expect(outcome.drop.answered, 1);
  });

  test('a wrong answer keeps the card locked and marks it as missed', () async {
    final drop = (await repo.getTodayDrop(preferredFields: const [])).toNullable()!;
    final card = catalog.card(drop.caseIds.first);

    final outcome = (await repo.answerCase(cardId: card.id, saysHolds: !card.scenario.holds)).toNullable()!;

    expect(outcome.correct, isFalse);
    expect(outcome.xpGained, 0);
    expect(outcome.progress.has(card.id), isFalse);
    expect(outcome.progress.missed, contains(card.id));
    expect(outcome.progress.accuracy, 0);
  });

  test('the same case cannot be answered twice', () async {
    final drop = (await repo.getTodayDrop(preferredFields: const [])).toNullable()!;
    final id = drop.caseIds.first;
    await repo.answerCase(cardId: id, saysHolds: true);
    final again = await repo.answerCase(cardId: id, saysHolds: true);
    expect(again.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('progress survives through the data source and can be reset', () async {
    final drop = (await repo.getTodayDrop(preferredFields: const [])).toNullable()!;
    final card = catalog.card(drop.caseIds.first);
    await repo.answerCase(cardId: card.id, saysHolds: card.scenario.holds);

    final reloaded = GameRepositoryImpl(catalog: catalogSource, local: store, clock: () => now);
    expect((await reloaded.getProgress()).toNullable()!.xp, card.rarity.xp);

    await reloaded.resetProgress();
    expect((await reloaded.getProgress()).toNullable()!.xp, 0);
  });
}
