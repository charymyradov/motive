import 'package:equatable/equatable.dart';

import 'motive_card.dart';
import 'psych_field.dart';

/// All fields and cards available in the game.
class GameCatalog extends Equatable {
  GameCatalog({required this.fields, required this.cards})
      : _cards = {for (final c in cards) c.id: c},
        _fields = {for (final f in fields) f.id: f};

  final List<PsychField> fields;
  final List<MotiveCard> cards;
  final Map<String, MotiveCard> _cards;
  final Map<String, PsychField> _fields;

  MotiveCard card(String id) => _cards[id]!;
  MotiveCard? cardOrNull(String id) => _cards[id];
  PsychField field(String id) => _fields[id]!;
  List<MotiveCard> cardsIn(String fieldId) => cards.where((c) => c.fieldId == fieldId).toList();

  @override
  List<Object?> get props => [fields, cards];
}
