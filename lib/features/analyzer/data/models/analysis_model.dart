import 'package:hive_ce/hive.dart';

import '../../../../core/constants/hive_constants.dart';
import '../../domain/entities/analysis.dart';

Map<int, dynamic> _readFields(BinaryReader reader) {
  final n = reader.readByte();
  return {for (var i = 0; i < n; i++) reader.readByte(): reader.read()};
}

class TechniqueModel {
  const TechniqueModel({required this.name, required this.quote, required this.how, required this.intensity});

  final String name;
  final String quote;
  final String how;
  final int intensity;

  /// Parses one technique of the Claude JSON answer.
  factory TechniqueModel.fromJson(Map<String, dynamic> json) => TechniqueModel(
        name: (json['name'] ?? '').toString().trim(),
        quote: (json['quote'] ?? '').toString().trim(),
        how: (json['how'] ?? '').toString().trim(),
        intensity: ((json['intensity'] as num?)?.round() ?? 1).clamp(1, 3),
      );

  factory TechniqueModel.fromEntity(Technique e) =>
      TechniqueModel(name: e.name, quote: e.quote, how: e.how, intensity: e.intensity);

  Technique toEntity() => Technique(name: name, quote: quote, how: how, intensity: intensity);
}

class AnalysisModel {
  const AnalysisModel({
    required this.id,
    required this.createdAt,
    required this.text,
    required this.hadImage,
    required this.pressure,
    required this.summary,
    required this.techniques,
    required this.source,
  });

  final String id;
  final DateTime createdAt;
  final String text;
  final bool hadImage;
  final int pressure;
  final String summary;
  final List<TechniqueModel> techniques;
  final String source;

  factory AnalysisModel.fromEntity(Analysis e) => AnalysisModel(
        id: e.id,
        createdAt: e.createdAt,
        text: e.text,
        hadImage: e.hadImage,
        pressure: e.pressure,
        summary: e.summary,
        techniques: e.techniques.map(TechniqueModel.fromEntity).toList(),
        source: e.source.name,
      );

  Analysis toEntity() => Analysis(
        id: id,
        createdAt: createdAt,
        text: text,
        hadImage: hadImage,
        pressure: pressure,
        summary: summary,
        techniques: List.unmodifiable(techniques.map((t) => t.toEntity())),
        source: AnalysisSource.values.asNameMap()[source] ?? AnalysisSource.offline,
      );
}

class TechniqueModelAdapter extends TypeAdapter<TechniqueModel> {
  @override
  final int typeId = HiveTypeIds.technique;

  @override
  TechniqueModel read(BinaryReader reader) {
    final f = _readFields(reader);
    return TechniqueModel(
      name: f[0] as String? ?? '',
      quote: f[1] as String? ?? '',
      how: f[2] as String? ?? '',
      intensity: f[3] as int? ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, TechniqueModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quote)
      ..writeByte(2)
      ..write(obj.how)
      ..writeByte(3)
      ..write(obj.intensity);
  }
}

class AnalysisModelAdapter extends TypeAdapter<AnalysisModel> {
  @override
  final int typeId = HiveTypeIds.analysis;

  @override
  AnalysisModel read(BinaryReader reader) {
    final f = _readFields(reader);
    return AnalysisModel(
      id: f[0] as String,
      createdAt: f[1] as DateTime,
      text: f[2] as String? ?? '',
      hadImage: f[3] as bool? ?? false,
      pressure: f[4] as int? ?? 0,
      summary: f[5] as String? ?? '',
      techniques: (f[6] as List? ?? const []).cast<TechniqueModel>(),
      source: f[7] as String? ?? AnalysisSource.offline.name,
    );
  }

  @override
  void write(BinaryWriter writer, AnalysisModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.hadImage)
      ..writeByte(4)
      ..write(obj.pressure)
      ..writeByte(5)
      ..write(obj.summary)
      ..writeByte(6)
      ..write(obj.techniques)
      ..writeByte(7)
      ..write(obj.source);
  }
}
