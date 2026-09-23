abstract final class AppConstants {
  static const appName = 'Motive';

  /// Number of cases in one daily drop.
  static const dropSize = 8;

  /// Cards needed in one field to earn its title.
  static const cardsPerField = 6;

  /// XP for answering an already collected card correctly.
  static const reviewXp = 10;

  /// Hour of the daily drop reminder notification.
  static const reminderHour = 8;

  static const claudeEndpoint = 'https://api.anthropic.com/v1/messages';
  static const claudeModel = 'claude-opus-5';
  static const claudeApiVersion = '2023-06-01';
  static const claudeFallbackBeta = 'server-side-fallback-2026-07-01';

  /// How many analyses are kept in the local history.
  static const maxHistory = 30;
}
