import 'package:equatable/equatable.dart';

import 'case_answer.dart';

/// The set of cases served on one calendar day.
class DailyDrop extends Equatable {
  const DailyDrop({required this.dayKey, required this.caseIds, this.answers = const {}});

  final String dayKey;
  final List<String> caseIds;
  final Map<String, CaseAnswer> answers;

  int get total => caseIds.length;
  int get answered => answers.length;
  bool get isComplete => total > 0 && answered >= total;
  double get progress => total == 0 ? 0 : answered / total;

  CaseAnswer? answerFor(String cardId) => answers[cardId];

  DailyDrop withAnswer(CaseAnswer a) =>
      DailyDrop(dayKey: dayKey, caseIds: caseIds, answers: {...answers, a.cardId: a});

  @override
  List<Object?> get props => [dayKey, caseIds, answers];
}
