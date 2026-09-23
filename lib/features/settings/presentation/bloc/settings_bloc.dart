import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_settings.dart';
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
  })  : _get = getSettings,
        _save = saveSettings,
        _reminder = setDailyReminder,
        super(const SettingsState()) {
    on<SettingsStarted>(_onStarted);
    on<ThemeModeChanged>((e, emit) => _update(emit, state.settings.copyWith(themeMode: e.mode)));
    on<ReminderToggled>(_onReminder);
    on<ArenasChanged>((e, emit) => _update(emit, state.settings.copyWith(pickedFields: e.fieldIds)));
    on<OnboardingFinished>(_onOnboardingFinished);
    on<OnboardingReplayRequested>((e, emit) => _update(emit, state.settings.copyWith(onboarded: false)));
    on<UserNameChanged>((e, emit) => _update(emit, state.settings.copyWith(userName: e.name.trim())));
    on<ApiKeyChanged>((e, emit) async {
      await _update(emit, state.settings.copyWith(apiKey: e.apiKey.trim()));
      emit(state.withNotice(e.apiKey.trim().isEmpty ? 'Using the offline analyzer.' : 'Claude analyzer connected.'));
    });
  }

  final GetSettings _get;
  final SaveSettings _save;
  final SetDailyReminder _reminder;

  Future<void> _onStarted(SettingsStarted event, Emitter<SettingsState> emit) async {
    final result = await _get(const NoParams());
    result.match(
      (f) => emit(state.copyWith(status: SettingsStatus.ready).withNotice(f.message)),
      (s) => emit(state.copyWith(status: SettingsStatus.ready, settings: s)),
    );
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
    final result = await _reminder(event.enabled);
    final active = result.getOrElse((_) => false);
    await _update(emit, state.settings.copyWith(reminderEnabled: active));
    if (event.enabled && !active) {
      emit(state.withNotice(result.isLeft() ? 'Could not set the reminder.' : 'Allow notifications to get the daily reminder.'));
    }
  }

  Future<void> _onOnboardingFinished(OnboardingFinished event, Emitter<SettingsState> emit) async {
    await _update(emit, state.settings.copyWith(onboarded: true, pickedFields: event.fieldIds));
    if (state.settings.reminderEnabled) {
      final result = await _reminder(true);
      final active = result.getOrElse((_) => false);
      if (!active) await _update(emit, state.settings.copyWith(reminderEnabled: false));
    }
  }
}
