/// Box names and adapter type ids used by Hive.
///
/// Type ids must never change once released, otherwise stored data can no
/// longer be decoded.
abstract final class HiveBoxes {
  static const settings = 'settings_box';
  static const game = 'game_box';
  static const analyses = 'analyses_box';
}

abstract final class HiveTypeIds {
  static const settings = 0;
  static const caseAnswer = 1;
  static const dailyDrop = 2;
  static const progress = 3;
  static const analysis = 4;
  static const technique = 5;
}

abstract final class HiveKeys {
  static const settings = 'settings';
  static const progress = 'progress';
  static const drop = 'drop';
}
