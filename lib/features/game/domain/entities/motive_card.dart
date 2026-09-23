import 'package:equatable/equatable.dart';

import 'rarity.dart';

/// A real-life case ending in a hypothesis the player judges.
class CaseScenario extends Equatable {
  const CaseScenario({required this.text, required this.hypothesis, required this.holds});

  final String text;
  final String hypothesis;

  /// Whether the hypothesis is the correct explanation.
  final bool holds;

  @override
  List<Object?> get props => [text, hypothesis, holds];
}

/// A collectible card: one psychological force and the case that reveals it.
class MotiveCard extends Equatable {
  const MotiveCard({
    required this.id,
    required this.number,
    required this.fieldId,
    required this.rarity,
    required this.force,
    required this.question,
    required this.why,
    required this.scenario,
  });

  final String id;

  /// Display number, e.g. "07".
  final String number;
  final String fieldId;
  final Rarity rarity;

  /// Name of the force, e.g. "Anchoring".
  final String force;

  /// The hook question shown on the card.
  final String question;

  /// Explanation of how the force works.
  final String why;
  final CaseScenario scenario;

  @override
  List<Object?> get props => [id];
}
