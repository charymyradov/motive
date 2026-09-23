import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<Either<Failure, AppSettings>> getSettings();

  Future<Either<Failure, AppSettings>> saveSettings(AppSettings settings);
}

abstract interface class ReminderRepository {
  /// Turns the daily drop reminder on or off.
  ///
  /// Returns whether the reminder is active afterwards; enabling it can end
  /// up `false` when the user denies the notification permission.
  Future<Either<Failure, bool>> setDailyReminder(bool enabled);
}
