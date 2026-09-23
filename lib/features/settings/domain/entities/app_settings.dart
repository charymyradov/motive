import 'package:equatable/equatable.dart';

enum AppThemeMode { dark, light }

class AppSettings extends Equatable {
  const AppSettings({
    this.onboarded = false,
    this.themeMode = AppThemeMode.dark,
    this.reminderEnabled = true,
    this.pickedFields = const ['ms', 'mm'],
    this.userName = '',
    this.apiKey = '',
  });

  final bool onboarded;
  final AppThemeMode themeMode;
  final bool reminderEnabled;

  /// Field ids the player wants to see first ("arenas").
  final List<String> pickedFields;
  final String userName;

  /// Claude API key for the online analyzer. Empty = offline analyzer only.
  final String apiKey;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  AppSettings copyWith({
    bool? onboarded,
    AppThemeMode? themeMode,
    bool? reminderEnabled,
    List<String>? pickedFields,
    String? userName,
    String? apiKey,
  }) {
    return AppSettings(
      onboarded: onboarded ?? this.onboarded,
      themeMode: themeMode ?? this.themeMode,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      pickedFields: pickedFields ?? this.pickedFields,
      userName: userName ?? this.userName,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  @override
  List<Object?> get props => [onboarded, themeMode, reminderEnabled, pickedFields, userName, apiKey];
}
