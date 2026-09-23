import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/analysis.dart';

abstract interface class AnalyzerRepository {
  /// Analyzes a post and stores the result in the local history.
  Future<Either<Failure, Analysis>> analyze(AnalysisRequest request);

  /// Newest first.
  Future<Either<Failure, List<Analysis>>> getHistory();

  Future<Either<Failure, Unit>> deleteAnalysis(String id);
}
