import 'package:hive_ce/hive.dart';

import '../../../../core/constants/hive_constants.dart';
import '../../domain/entities/app_settings.dart';

class SettingsModel {
  const SettingsModel({
    required this.onboarded,
    required this.themeMode,
    required this.reminderEnabled,
    required this.pickedFields,
    required this.userName,
    required this.apiKey,
  });

  final bool onboarded;
  final String themeMode;
  final bool reminderEnabled;
  final List<String> pickedFields;
  final String userName;
  final String apiKey;

  factory SettingsModel.fromEntity(AppSettings e) => SettingsModel(
        onboarded: e.onboarded,
        themeMode: e.themeMode.name,
        reminderEnabled: e.reminderEnabled,
        pickedFields: List.of(e.pickedFields),
        userName: e.userName,
        apiKey: e.apiKey,
      );

  AppSettings toEntity() => AppSettings(
        onboarded: onboarded,
        themeMode: AppThemeMode.values.asNameMap()[themeMode] ?? AppThemeMode.dark,
        reminderEnabled: reminderEnabled,
        pickedFields: List.unmodifiable(pickedFields),
        userName: userName,
        apiKey: apiKey,
      );
}

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = HiveTypeIds.settings;

  @override
  SettingsModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = {for (var i = 0; i < n; i++) reader.readByte(): reader.read()};
    const d = AppSettings();
    return SettingsModel(
      onboarded: f[0] as bool? ?? d.onboarded,
      themeMode: f[1] as String? ?? d.themeMode.name,
      reminderEnabled: f[2] as bool? ?? d.reminderEnabled,
      pickedFields: (f[3] as List? ?? d.pickedFields).cast<String>(),
      userName: f[4] as String? ?? d.userName,
      apiKey: f[5] as String? ?? d.apiKey,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.onboarded)
      ..writeByte(1)
      ..write(obj.themeMode)
      ..writeByte(2)
      ..write(obj.reminderEnabled)
      ..writeByte(3)
      ..write(obj.pickedFields)
      ..writeByte(4)
      ..write(obj.userName)
      ..writeByte(5)
      ..write(obj.apiKey);
  }
}
