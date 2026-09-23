import 'package:flutter_test/flutter_test.dart';
import 'package:motive/features/game/data/datasources/card_catalog_datasource.dart';
import 'package:motive/features/game/domain/entities/player_progress.dart';
import 'package:motive/features/game/domain/services/drop_planner.dart';

void main() {
  final catalog = const BundledCardCatalogDataSource().load();
  const planner = DropPlanner();

  test('plans 8 unique cases and serves preferred arenas first', () {
    final ids = planner.plan(
      catalog: catalog,
      progress: PlayerProgress.empty,
      preferredFields: const ['mm'],
      dayKey: '2026-09-23',
    );
    expect(ids, hasLength(8));
    expect(ids.toSet(), hasLength(8));
    // All 6 Money Mind cards are uncollected, so they lead the drop.
    expect(ids.take(6).every((id) => catalog.card(id).fieldId == 'mm'), isTrue);
  });

  test('is deterministic for the same day', () {
    List<String> plan() => planner.plan(
          catalog: catalog,
          progress: PlayerProgress.empty,
          preferredFields: const ['ms', 'ng'],
          dayKey: '2026-09-23',
        );
    expect(plan(), plan());
  });

  test('brings missed cases back and skips collected ones', () {
    final progress = PlayerProgress(
      collected: {for (final c in catalog.cards.take(10)) c.id: DateTime(2026)},
      missed: const {'ng6'},
    );
    final ids = planner.plan(catalog: catalog, progress: progress, preferredFields: const [], dayKey: '2026-09-24');
    expect(ids, contains('ng6'));
    expect(ids.where(progress.has), isEmpty);
  });

  test('falls back to review cards when almost everything is collected', () {
    final progress = PlayerProgress(
      collected: {for (final c in catalog.cards.take(22)) c.id: DateTime(2026)},
    );
    final ids = planner.plan(catalog: catalog, progress: progress, preferredFields: const [], dayKey: '2026-09-25');
    expect(ids, hasLength(8));
    expect(ids.where((id) => !progress.has(id)), hasLength(2));
  });
}
