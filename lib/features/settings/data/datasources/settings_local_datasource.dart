import 'package:hive_ce/hive.dart';

import '../../../../core/constants/hive_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_settings.dart';
import '../models/settings_model.dart';

abstract interface class SettingsLocalDataSource {
  SettingsModel getSettings();
  Future<void> saveSettings(SettingsModel settings);
}

class HiveSettingsLocalDataSource implements SettingsLocalDataSource {
  const HiveSettingsLocalDataSource(this._box);
  final Box<SettingsModel> _box;

  @override
  SettingsModel getSettings() {
    try {
      return _box.get(HiveKeys.settings) ?? SettingsModel.fromEntity(const AppSettings());
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    try {
      await _box.put(HiveKeys.settings, settings);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
