import 'dart:math';

import '../../../../core/constants/app_constants.dart';
import '../entities/game_catalog.dart';
import '../entities/motive_card.dart';
import '../entities/player_progress.dart';

/// Decides which cases land in a day's drop. Pure and deterministic for a
/// given day, so it is easy to test.
///
/// Priority:
/// 1. up to two previously missed cases ("it comes back around"),
/// 2. new cards, the player's preferred arenas first,
/// 3. remaining missed cases,
/// 4. once almost everything is collected, collected cards as review.
class DropPlanner {
  const DropPlanner();

  List<String> plan({
    required GameCatalog catalog,
    required PlayerProgress progress,
    required List<String> preferredFields,
    required String dayKey,
    int size = AppConstants.dropSize,
  }) {
    final rng = Random(_seed(dayKey));
    final preferred = preferredFields.toSet();

    List<MotiveCard> shuffledPreferredFirst(Iterable<MotiveCard> cards) {
      final list = cards.toList()..shuffle(rng);
      list.sort((a, b) => (preferred.contains(b.fieldId) ? 1 : 0) - (preferred.contains(a.fieldId) ? 1 : 0));
      return list;
    }

    final uncollected = catalog.cards.where((c) => !progress.has(c.id));
    final missed = shuffledPreferredFirst(uncollected.where((c) => progress.missed.contains(c.id)));
    final fresh = shuffledPreferredFirst(uncollected.where((c) => !progress.missed.contains(c.id)));
    final review = catalog.cards.where((c) => progress.has(c.id)).toList()..shuffle(rng);

    final picked = <String>[];
    void take(Iterable<MotiveCard> from, [int? max]) {
      var n = 0;
      for (final c in from) {
        if (picked.length >= size || (max != null && n >= max)) return;
        if (picked.contains(c.id)) continue;
        picked.add(c.id);
        n++;
      }
    }

    take(missed, 2);
    take(fresh);
    take(missed);
    take(review);

    // Serve the player's arenas first, like the prototype feed.
    final order = {for (var i = 0; i < picked.length; i++) picked[i]: i};
    picked.sort((a, b) {
      final pa = preferred.contains(catalog.card(a).fieldId) ? 0 : 1;
      final pb = preferred.contains(catalog.card(b).fieldId) ? 0 : 1;
      return pa != pb ? pa - pb : order[a]! - order[b]!;
    });
    return picked;
  }

  int _seed(String dayKey) => dayKey.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x7fffffff);
}
