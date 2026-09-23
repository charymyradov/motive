import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);
  final SettingsLocalDataSource _local;

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      return Right(_local.getSettings().toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppSettings>> saveSettings(AppSettings settings) async {
    try {
      await _local.saveSettings(SettingsModel.fromEntity(settings));
      return Right(settings);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}

class ReminderRepositoryImpl implements ReminderRepository {
  const ReminderRepositoryImpl(this._notifications);
  final NotificationService _notifications;

  @override
  Future<Either<Failure, bool>> setDailyReminder(bool enabled) async {
    try {
      if (!enabled) {
        await _notifications.cancelDailyDrop();
        return const Right(false);
      }
      final granted = await _notifications.requestPermission();
      if (!granted) return const Right(false);
      await _notifications.scheduleDailyDrop();
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure('Could not schedule the reminder: $e'));
    }
  }
}
