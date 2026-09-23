import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/analysis.dart';
import '../repositories/analyzer_repository.dart';

class AnalyzePost implements UseCase<Analysis, AnalysisRequest> {
  const AnalyzePost(this._repo);
  final AnalyzerRepository _repo;

  @override
  Future<Either<Failure, Analysis>> call(AnalysisRequest params) async {
    if (params.isEmpty) return const Left(ValidationFailure('Paste a post or attach a screenshot first.'));
    return _repo.analyze(params);
  }
}

class GetAnalysisHistory implements UseCase<List<Analysis>, NoParams> {
  const GetAnalysisHistory(this._repo);
  final AnalyzerRepository _repo;

  @override
  Future<Either<Failure, List<Analysis>>> call(NoParams params) => _repo.getHistory();
}

class DeleteAnalysis implements UseCase<Unit, String> {
  const DeleteAnalysis(this._repo);
  final AnalyzerRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(String id) => _repo.deleteAnalysis(id);
}
