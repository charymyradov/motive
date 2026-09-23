import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../settings/data/datasources/settings_local_datasource.dart';
import '../../domain/entities/analysis.dart';
import '../../domain/repositories/analyzer_repository.dart';
import '../datasources/analysis_local_datasource.dart';
import '../datasources/claude_analyzer_datasource.dart';
import '../datasources/offline_analyzer_datasource.dart';
import '../models/analysis_model.dart';

/// Uses Claude when an API key is configured and falls back to the offline
/// engine for text when there is no key or no connection.
class AnalyzerRepositoryImpl implements AnalyzerRepository {
  AnalyzerRepositoryImpl({
    required this._remote,
    required this._offline,
    required this._history,
    required this._settings,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final RemoteAnalyzerDataSource _remote;
  final OfflineAnalyzerDataSource _offline;
  final AnalysisLocalDataSource _history;
  final SettingsLocalDataSource _settings;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, Analysis>> analyze(AnalysisRequest request) async {
    final text = request.text.trim();
    String apiKey;
    try {
      apiKey = _settings.getSettings().apiKey.trim();
    } on CacheException {
      apiKey = '';
    }

    RawAnalysis raw;
    var source = AnalysisSource.offline;

    if (apiKey.isNotEmpty) {
      try {
        raw = await _remote.analyze(
          apiKey: apiKey,
          text: text,
          image: request.imageBytes,
          imageMimeType: request.imageMimeType,
        );
        source = AnalysisSource.claude;
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        if (text.isEmpty) return Left(NetworkFailure('${e.message} Screenshots need a connection.'));
        raw = _offline.analyze(text);
      }
    } else {
      if (text.isEmpty) {
        return const Left(ValidationFailure(
          'Reading screenshots needs the Claude engine. Add an API key in Me → Analyzer engine, or paste the text of the post.',
        ));
      }
      raw = _offline.analyze(text);
    }

    final now = _clock();
    final analysis = Analysis(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      text: text,
      hadImage: request.hasImage,
      pressure: raw.pressure,
      summary: raw.summary,
      techniques: raw.techniques.map((t) => t.toEntity()).toList(),
      source: source,
    );

    try {
      await _history.save(AnalysisModel.fromEntity(analysis));
    } on CacheException {
      // History is a convenience; the analysis itself still succeeded.
    }
    return Right(analysis);
  }

  @override
  Future<Either<Failure, List<Analysis>>> getHistory() async {
    try {
      return Right(_history.getAll().map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAnalysis(String id) async {
    try {
      await _history.delete(id);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
