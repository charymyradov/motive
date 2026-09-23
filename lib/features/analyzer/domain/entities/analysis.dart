import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum AnalysisSource { claude, offline }

/// One persuasion lever found in a post.
class Technique extends Equatable {
  const Technique({required this.name, required this.quote, required this.how, required this.intensity});

  final String name;

  /// Short excerpt from the post that shows the technique.
  final String quote;

  /// Plain explanation of how it works on the reader.
  final String how;

  /// 1 (light) .. 3 (heavy).
  final int intensity;

  @override
  List<Object?> get props => [name, quote, how, intensity];
}

class Analysis extends Equatable {
  const Analysis({
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

  /// The analyzed post text (may be empty when only a screenshot was sent).
  final String text;
  final bool hadImage;

  /// 0..100, how hard the post pushes the reader.
  final int pressure;
  final String summary;
  final List<Technique> techniques;
  final AnalysisSource source;

  String get label => pressure > 60
      ? 'Full-court press'
      : pressure > 30
          ? 'Working on you'
          : 'Mild nudge';

  @override
  List<Object?> get props => [id, createdAt, text, hadImage, pressure, summary, techniques, source];
}

/// Input of the analyzer.
class AnalysisRequest extends Equatable {
  const AnalysisRequest({this.text = '', this.imageBytes, this.imageMimeType});

  final String text;
  final Uint8List? imageBytes;
  final String? imageMimeType;

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;
  bool get isEmpty => text.trim().isEmpty && !hasImage;

  @override
  List<Object?> get props => [text, imageBytes?.length, imageMimeType];
}
