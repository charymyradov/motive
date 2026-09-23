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

class SetDailyReminder implements UseCase<bool, bool> {
  const SetDailyReminder(this._repo);
  final ReminderRepository _repo;

  @override
  Future<Either<Failure, bool>> call(bool enabled) => _repo.setDailyReminder(enabled);
}
