import 'package:hive_ce/hive.dart';

import '../../../../core/constants/hive_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/game_models.dart';

abstract interface class GameLocalDataSource {
  ProgressModel? getProgress();
  Future<void> saveProgress(ProgressModel progress);
  DailyDropModel? getDrop();
  Future<void> saveDrop(DailyDropModel drop);
  Future<void> clear();
}

class HiveGameLocalDataSource implements GameLocalDataSource {
  const HiveGameLocalDataSource(this._box);

  /// Holds a [ProgressModel] under [HiveKeys.progress] and a [DailyDropModel]
  /// under [HiveKeys.drop].
  final Box<dynamic> _box;

  @override
  ProgressModel? getProgress() => _guard(() => _box.get(HiveKeys.progress) as ProgressModel?);

  @override
  Future<void> saveProgress(ProgressModel progress) => _guardAsync(() => _box.put(HiveKeys.progress, progress));

  @override
  DailyDropModel? getDrop() => _guard(() => _box.get(HiveKeys.drop) as DailyDropModel?);

  @override
  Future<void> saveDrop(DailyDropModel drop) => _guardAsync(() => _box.put(HiveKeys.drop, drop));

  @override
  Future<void> clear() => _guardAsync(_box.clear);

  T _guard<T>(T Function() f) {
    try {
      return f();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  Future<void> _guardAsync(Future<Object?> Function() f) async {
    try {
      await f();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
