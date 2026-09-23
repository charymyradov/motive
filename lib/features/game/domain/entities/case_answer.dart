import 'package:equatable/equatable.dart';

class CaseAnswer extends Equatable {
  const CaseAnswer({
    required this.cardId,
    required this.saidHolds,
    required this.correct,
    required this.answeredAt,
  });

  final String cardId;
  final bool saidHolds;
  final bool correct;
  final DateTime answeredAt;

  @override
  List<Object?> get props => [cardId, saidHolds, correct, answeredAt];
}
