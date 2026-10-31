import 'package:equatable/equatable.dart';
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
  Future<Either<Failure, bool>> setDailyReminder(ReminderRequest request);
}

/// When (local time) and whether the daily drop reminder should fire.
class ReminderRequest extends Equatable {
  const ReminderRequest({required this.enabled, required this.hour, required this.minute});

  final bool enabled;
  final int hour;
  final int minute;

  @override
  List<Object?> get props => [enabled, hour, minute];
}
