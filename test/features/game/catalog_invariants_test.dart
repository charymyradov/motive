import 'package:flutter_test/flutter_test.dart';
import 'package:motive/features/game/data/datasources/card_catalog_datasource.dart';
import 'package:motive/features/game/domain/entities/rarity.dart';

void main() {
  test('phase 1 catalog invariants', () {
    final c = const BundledCardCatalogDataSource().load();
    expect(c.fields, hasLength(8));
    expect(c.cards, hasLength(48));
    expect(c.cards.map((e) => e.id).toSet(), hasLength(48));
    expect(c.cards.map((e) => e.number).toSet(), hasLength(48));
    for (final f in c.fields) {
      final cards = c.cardsIn(f.id);
      expect(cards, hasLength(6), reason: 'arena ${f.id}');
      expect(
        cards.where((e) => e.rarity == Rarity.legendary).length,
        greaterThanOrEqualTo(1),
        reason: 'arena ${f.id} legendary',
      );
    }
    final legendary = c.cards.where((e) => e.rarity == Rarity.legendary).length;
    expect(legendary, 8, reason: 'legendary count');
    // Every scenario carries a hypothesis and a boolean answer.
    for (final card in c.cards) {
      expect(card.scenario.hypothesis, isNotEmpty, reason: card.id);
      expect(card.force, isNotEmpty, reason: card.id);
      expect(card.why.length, greaterThan(40), reason: card.id);
    }
  });
}
