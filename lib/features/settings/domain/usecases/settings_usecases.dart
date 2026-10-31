import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings implements UseCase<AppSettings, NoParams> {
  const GetSettings(this._repo);
  final SettingsRepository _repo;

  @override
  Future<Either<Failure, AppSettings>> call(NoParams params) => _repo.getSettings();
}

class SaveSettings implements UseCase<AppSettings, AppSettings> {
  const SaveSettings(this._repo);
  final SettingsRepository _repo;

  @override
  Future<Either<Failure, AppSettings>> call(AppSettings params) => _repo.saveSettings(params);
}

class SetDailyReminder implements UseCase<bool, ReminderRequest> {
  const SetDailyReminder(this._repo);
  final ReminderRepository _repo;

  @override
  Future<Either<Failure, bool>> call(ReminderRequest params) => _repo.setDailyReminder(params);
}

/// Re-arms the daily drop reminder with the time currently stored in
/// settings — used right after the user picks a new reminder time.
class RescheduleReminder implements UseCase<bool, NoParams> {
  const RescheduleReminder(this._settings, this._reminders);
  final SettingsRepository _settings;
  final ReminderRepository _reminders;

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    final result = await _settings.getSettings();
    return result.fold(
      (f) => Left(f),
      (s) => _reminders.setDailyReminder(
        ReminderRequest(enabled: s.reminderEnabled, hour: s.reminderHour, minute: s.reminderMinute),
      ),
    );
  }
}
