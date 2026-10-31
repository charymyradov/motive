import 'package:hive_ce/hive.dart';

import '../../../../core/constants/hive_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/game_models.dart';

abstract interface class GameLocalDataSource {
  ProgressModel? getProgress();
  Future<void> saveProgress(ProgressModel progress);
  DailyDropModel? getDrop();
  Future<void> saveDrop(DailyDropModel drop);

  /// Personal notes, `card id -> text`.
  Map<String, String> getNotes();
  Future<void> saveNote(String cardId, String text);

  /// Wipes progress and today's drop, keeping personal notes.
  Future<void> clear();
}

class HiveGameLocalDataSource implements GameLocalDataSource {
  const HiveGameLocalDataSource(this._box);

  /// Holds a [ProgressModel] under [HiveKeys.progress], a [DailyDropModel]
  /// under [HiveKeys.drop] and `card id -> note` under [HiveKeys.notes].
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
  Map<String, String> getNotes() => _guard(() {
        final raw = _box.get(HiveKeys.notes);
        if (raw is! Map) return const <String, String>{};
        return raw.map((k, v) => MapEntry(k as String, v as String));
      });

  @override
  Future<void> saveNote(String cardId, String text) => _guardAsync(() {
        final notes = Map<String, String>.from(getNotes());
        if (text.trim().isEmpty) {
          notes.remove(cardId);
        } else {
          notes[cardId] = text.trim();
        }
        return _box.put(HiveKeys.notes, notes);
      });

  @override
  Future<void> clear() => _guardAsync(() async {
        // Notes are the player's own annotations — a progress reset keeps them.
        await _box.delete(HiveKeys.progress);
        await _box.delete(HiveKeys.drop);
      });

  T _guard<T>(T Function() f) {
    try {
      return f();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  Future<void> _guardAsync(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
