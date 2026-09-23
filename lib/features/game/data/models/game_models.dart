import 'package:hive_ce/hive.dart';

import '../../../../core/constants/hive_constants.dart';
import '../../domain/entities/case_answer.dart';
import '../../domain/entities/daily_drop.dart';
import '../../domain/entities/player_progress.dart';

// Adapters are written by hand (no build_runner) and use the same
// "field index + value" layout as generated Hive adapters, so fields can be
// added later without breaking stored data.

Map<int, dynamic> _readFields(BinaryReader reader) {
  final n = reader.readByte();
  return {for (var i = 0; i < n; i++) reader.readByte(): reader.read()};
}

class CaseAnswerModel {
  const CaseAnswerModel({
    required this.cardId,
    required this.saidHolds,
    required this.correct,
    required this.answeredAt,
  });

  final String cardId;
  final bool saidHolds;
  final bool correct;
  final DateTime answeredAt;

  factory CaseAnswerModel.fromEntity(CaseAnswer e) =>
      CaseAnswerModel(cardId: e.cardId, saidHolds: e.saidHolds, correct: e.correct, answeredAt: e.answeredAt);

  CaseAnswer toEntity() => CaseAnswer(cardId: cardId, saidHolds: saidHolds, correct: correct, answeredAt: answeredAt);
}

class CaseAnswerModelAdapter extends TypeAdapter<CaseAnswerModel> {
  @override
  final int typeId = HiveTypeIds.caseAnswer;

  @override
  CaseAnswerModel read(BinaryReader reader) {
    final f = _readFields(reader);
    return CaseAnswerModel(
      cardId: f[0] as String,
      saidHolds: f[1] as bool,
      correct: f[2] as bool,
      answeredAt: f[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CaseAnswerModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.cardId)
      ..writeByte(1)
      ..write(obj.saidHolds)
      ..writeByte(2)
      ..write(obj.correct)
      ..writeByte(3)
      ..write(obj.answeredAt);
  }
}

class DailyDropModel {
  const DailyDropModel({required this.dayKey, required this.caseIds, required this.answers});

  final String dayKey;
  final List<String> caseIds;
  final Map<String, CaseAnswerModel> answers;

  factory DailyDropModel.fromEntity(DailyDrop e) => DailyDropModel(
        dayKey: e.dayKey,
        caseIds: List.of(e.caseIds),
        answers: e.answers.map((k, v) => MapEntry(k, CaseAnswerModel.fromEntity(v))),
      );

  DailyDrop toEntity() => DailyDrop(
        dayKey: dayKey,
        caseIds: List.unmodifiable(caseIds),
        answers: Map.unmodifiable(answers.map((k, v) => MapEntry(k, v.toEntity()))),
      );
}

class DailyDropModelAdapter extends TypeAdapter<DailyDropModel> {
  @override
  final int typeId = HiveTypeIds.dailyDrop;

  @override
  DailyDropModel read(BinaryReader reader) {
    final f = _readFields(reader);
    return DailyDropModel(
      dayKey: f[0] as String,
      caseIds: (f[1] as List).cast<String>(),
      answers: (f[2] as Map? ?? const {}).cast<String, CaseAnswerModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyDropModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dayKey)
      ..writeByte(1)
      ..write(obj.caseIds)
      ..writeByte(2)
      ..write(obj.answers);
  }
}

class ProgressModel {
  const ProgressModel({
    required this.xp,
    required this.collected,
    required this.activeDays,
    required this.totalAnswers,
    required this.correctAnswers,
    required this.missed,
  });

  final int xp;
  final Map<String, DateTime> collected;
  final List<String> activeDays;
  final int totalAnswers;
  final int correctAnswers;
  final List<String> missed;

  factory ProgressModel.fromEntity(PlayerProgress e) => ProgressModel(
        xp: e.xp,
        collected: Map.of(e.collected),
        activeDays: e.activeDays.toList()..sort(),
        totalAnswers: e.totalAnswers,
        correctAnswers: e.correctAnswers,
        missed: e.missed.toList(),
      );

  PlayerProgress toEntity() => PlayerProgress(
        xp: xp,
        collected: Map.unmodifiable(collected),
        activeDays: Set.unmodifiable(activeDays),
        totalAnswers: totalAnswers,
        correctAnswers: correctAnswers,
        missed: Set.unmodifiable(missed),
      );
}

class ProgressModelAdapter extends TypeAdapter<ProgressModel> {
  @override
  final int typeId = HiveTypeIds.progress;

  @override
  ProgressModel read(BinaryReader reader) {
    final f = _readFields(reader);
    return ProgressModel(
      xp: f[0] as int? ?? 0,
      collected: (f[1] as Map? ?? const {}).cast<String, DateTime>(),
      activeDays: (f[2] as List? ?? const []).cast<String>(),
      totalAnswers: f[3] as int? ?? 0,
      correctAnswers: f[4] as int? ?? 0,
      missed: (f[5] as List? ?? const []).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProgressModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.xp)
      ..writeByte(1)
      ..write(obj.collected)
      ..writeByte(2)
      ..write(obj.activeDays)
      ..writeByte(3)
      ..write(obj.totalAnswers)
      ..writeByte(4)
      ..write(obj.correctAnswers)
      ..writeByte(5)
      ..write(obj.missed);
  }
}
