import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/analysis_model.dart';

abstract interface class AnalysisLocalDataSource {
  List<AnalysisModel> getAll();
  Future<void> save(AnalysisModel analysis);
  Future<void> delete(String id);
}

class HiveAnalysisLocalDataSource implements AnalysisLocalDataSource {
  const HiveAnalysisLocalDataSource(this._box);
  final Box<AnalysisModel> _box;

  @override
  List<AnalysisModel> getAll() {
    try {
      return _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> save(AnalysisModel analysis) async {
    try {
      await _box.put(analysis.id, analysis);
      final all = getAll();
      if (all.length > AppConstants.maxHistory) {
        await _box.deleteAll(all.skip(AppConstants.maxHistory).map((a) => a.id));
      }
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
