import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

enum AppThemeMode { dark, light, system }

class AppSettings extends Equatable {
  const AppSettings({
    this.onboarded = false,
    this.themeMode = AppThemeMode.dark,
    this.reminderEnabled = true,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.soundEnabled = true,
    this.pickedFields = AppConstants.defaultPickedFields,
    this.userName = '',
    this.apiKey = '',
    this.avatar,
  });

  final bool onboarded;
  final AppThemeMode themeMode;
  final bool reminderEnabled;

  /// Local time of the daily drop reminder.
  final int reminderHour;
  final int reminderMinute;

  /// Whether sound effects play at all (`SoundService.enabled`).
  final bool soundEnabled;

  /// Field ids the player wants to see first ("arenas").
  final List<String> pickedFields;
  final String userName;

  /// Claude API key for the online analyzer. Empty = offline analyzer only.
  final String apiKey;

  /// Profile photo, JPEG bytes downscaled before storage. Null = initial letter.
  final Uint8List? avatar;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  /// "08:00" style label for the reminder row.
  String get reminderLabel =>
      '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}';

  AppSettings copyWith({
    bool? onboarded,
    AppThemeMode? themeMode,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? soundEnabled,
    List<String>? pickedFields,
    String? userName,
    String? apiKey,
    Uint8List? avatar,
    bool clearAvatar = false,
  }) {
    return AppSettings(
      onboarded: onboarded ?? this.onboarded,
      themeMode: themeMode ?? this.themeMode,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      pickedFields: pickedFields ?? this.pickedFields,
      userName: userName ?? this.userName,
      apiKey: apiKey ?? this.apiKey,
      avatar: clearAvatar ? null : (avatar ?? this.avatar),
    );
  }

  @override
  List<Object?> get props =>
      [onboarded, themeMode, reminderEnabled, reminderHour, reminderMinute, soundEnabled, pickedFields, userName, apiKey, avatar];
}
