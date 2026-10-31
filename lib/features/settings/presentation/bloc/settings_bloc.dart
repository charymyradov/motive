import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/sound_service.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/settings_usecases.dart';

// ── Events ──────────────────────────────────────────────────────────────

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

class ThemeModeChanged extends SettingsEvent {
  const ThemeModeChanged(this.mode);
  final AppThemeMode mode;
  @override
  List<Object?> get props => [mode];
}

class ReminderToggled extends SettingsEvent {
  const ReminderToggled(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

class ReminderTimeChanged extends SettingsEvent {
  const ReminderTimeChanged(this.hour, this.minute);
  final int hour;
  final int minute;
  @override
  List<Object?> get props => [hour, minute];
}

class SoundToggled extends SettingsEvent {
  const SoundToggled(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

class ArenasChanged extends SettingsEvent {
  const ArenasChanged(this.fieldIds);
  final List<String> fieldIds;
  @override
  List<Object?> get props => [fieldIds];
}

class OnboardingFinished extends SettingsEvent {
  const OnboardingFinished(this.fieldIds);
  final List<String> fieldIds;
  @override
  List<Object?> get props => [fieldIds];
}

class OnboardingReplayRequested extends SettingsEvent {
  const OnboardingReplayRequested();
}

class UserNameChanged extends SettingsEvent {
  const UserNameChanged(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

class ApiKeyChanged extends SettingsEvent {
  const ApiKeyChanged(this.apiKey);
  final String apiKey;
  @override
  List<Object?> get props => [apiKey];
}

/// Sets (or, with null, removes) the profile photo.
class AvatarChanged extends SettingsEvent {
  const AvatarChanged(this.bytes);
  final Uint8List? bytes;
  @override
  List<Object?> get props => [bytes];
}

// ── State ───────────────────────────────────────────────────────────────

enum SettingsStatus { loading, ready }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.loading,
    this.settings = const AppSettings(),
    this.notice,
    this.noticeId = 0,
  });

  final SettingsStatus status;
  final AppSettings settings;

  /// One-shot message for a snackbar; [noticeId] changes every time.
  final String? notice;
  final int noticeId;

  SettingsState copyWith({SettingsStatus? status, AppSettings? settings}) =>
      SettingsState(status: status ?? this.status, settings: settings ?? this.settings, notice: notice, noticeId: noticeId);

  SettingsState withNotice(String message) =>
      SettingsState(status: status, settings: settings, notice: message, noticeId: noticeId + 1);

  @override
  List<Object?> get props => [status, settings, notice, noticeId];
}

// ── Bloc ────────────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required GetSettings getSettings,
    required SaveSettings saveSettings,
    required SetDailyReminder setDailyReminder,
    required RescheduleReminder rescheduleReminder,
    required SoundService soundService,
  })  : _get = getSettings,
        _save = saveSettings,
        _reminder = setDailyReminder,
        _reschedule = rescheduleReminder,
        _sound = soundService,
        super(const SettingsState()) {
    on<SettingsStarted>(_onStarted);
    on<ThemeModeChanged>((e, emit) => _update(emit, state.settings.copyWith(themeMode: e.mode)));
    on<ReminderToggled>(_onReminder);
    on<ReminderTimeChanged>(_onReminderTime);
    on<SoundToggled>(_onSound);
    on<ArenasChanged>((e, emit) => _update(emit, state.settings.copyWith(pickedFields: e.fieldIds)));
    on<OnboardingFinished>(_onOnboardingFinished);
    on<OnboardingReplayRequested>((e, emit) => _update(emit, state.settings.copyWith(onboarded: false)));
    on<UserNameChanged>((e, emit) => _update(emit, state.settings.copyWith(userName: e.name.trim())));
    on<ApiKeyChanged>((e, emit) async {
      await _update(emit, state.settings.copyWith(apiKey: e.apiKey.trim()));
      emit(state.withNotice(e.apiKey.trim().isEmpty ? 'Using the offline analyzer.' : 'Claude analyzer connected.'));
    });
    on<AvatarChanged>((e, emit) async {
      if (e.bytes == null) {
        await _update(emit, state.settings.copyWith(clearAvatar: true));
        emit(state.withNotice('Profile photo removed.'));
      } else {
        await _update(emit, state.settings.copyWith(avatar: e.bytes));
      }
    });
  }

  final GetSettings _get;
  final SaveSettings _save;
  final SetDailyReminder _reminder;
  final RescheduleReminder _reschedule;
  final SoundService _sound;

  Future<void> _onStarted(SettingsStarted event, Emitter<SettingsState> emit) async {
    final result = await _get(const NoParams());
    result.match(
      (f) => emit(state.copyWith(status: SettingsStatus.ready).withNotice(f.message)),
      (s) {
        _applySound(s.soundEnabled);
        emit(state.copyWith(status: SettingsStatus.ready, settings: s));
      },
    );
  }

  void _applySound(bool enabled, {bool audible = false}) {
    _sound.enabled = enabled;
    if (enabled && audible) _sound.playToggleClick();
  }

  Future<void> _onSound(SoundToggled event, Emitter<SettingsState> emit) async {
    await _update(emit, state.settings.copyWith(soundEnabled: event.enabled));
    _applySound(state.settings.soundEnabled, audible: true);
  }

  Future<void> _onReminderTime(ReminderTimeChanged event, Emitter<SettingsState> emit) async {
    await _update(emit, state.settings.copyWith(reminderHour: event.hour, reminderMinute: event.minute));
    if (!state.settings.reminderEnabled) return;
    final result = await _reschedule(const NoParams());
    final active = result.getOrElse((_) => false);
    emit(state.withNotice(active
        ? 'New cases will land at ${state.settings.reminderLabel}.'
        : 'Could not reschedule the reminder.'));
  }

  Future<void> _update(Emitter<SettingsState> emit, AppSettings next) async {
    final previous = state.settings;
    emit(state.copyWith(settings: next)); // optimistic
    final result = await _save(next);
    result.match(
      (f) => emit(state.copyWith(settings: previous).withNotice(f.message)),
      (_) {},
    );
  }

  Future<void> _onReminder(ReminderToggled event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(settings: state.settings.copyWith(reminderEnabled: event.enabled)));
    final s = state.settings;
    final result = await _reminder(ReminderRequest(enabled: event.enabled, hour: s.reminderHour, minute: s.reminderMinute));
    final active = result.getOrElse((_) => false);
    await _update(emit, state.settings.copyWith(reminderEnabled: active));
    if (event.enabled && !active) {
      emit(state.withNotice(result.isLeft() ? 'Could not set the reminder.' : 'Allow notifications to get the daily reminder.'));
    }
  }

  Future<void> _onOnboardingFinished(OnboardingFinished event, Emitter<SettingsState> emit) async {
    await _update(emit, state.settings.copyWith(onboarded: true, pickedFields: event.fieldIds));
    if (state.settings.reminderEnabled) {
      final s = state.settings;
      final result = await _reminder(
        ReminderRequest(enabled: true, hour: s.reminderHour, minute: s.reminderMinute),
      );
      final active = result.getOrElse((_) => false);
      if (!active) await _update(emit, state.settings.copyWith(reminderEnabled: false));
    }
  }
}
