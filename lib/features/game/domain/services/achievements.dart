import 'package:equatable/equatable.dart';

import '../entities/game_catalog.dart';
import '../entities/player_progress.dart';

/// Visual weight of an achievement, drawn as pips in the profile grid.
enum AchievementTier { bronze, silver, gold }

/// One badge the player can earn. Conditions are pure functions over
/// progress + catalog, so badges never need migrating — a badge added in a
/// later version simply lights up for players who already qualify.
class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.qualifies,
  });

  final String id;
  final String title;
  final String description;
  final AchievementTier tier;
  final bool Function(PlayerProgress progress, GameCatalog catalog) qualifies;

  @override
  List<Object?> get props => [id];
}

/// Every badge in the game. Order defines the grid order.
abstract final class Achievements {
  static final List<Achievement> all = [
    Achievement(
      id: 'first_card',
      title: 'First Blood',
      description: 'Collect your first card.',
      tier: AchievementTier.bronze,
      qualifies: _hasCards(1),
    ),
    Achievement(
      id: 'cards_10',
      title: 'Collector',
      description: 'Collect 10 cards.',
      tier: AchievementTier.bronze,
      qualifies: _hasCards(10),
    ),
    Achievement(
      id: 'cards_25',
      title: 'Deep Deck',
      description: 'Collect 25 cards.',
      tier: AchievementTier.silver,
      qualifies: _hasCards(25),
    ),
    Achievement(
      id: 'cards_48',
      title: 'Complete Set',
      description: 'Collect all 48 cards.',
      tier: AchievementTier.gold,
      qualifies: _hasCards(48),
    ),
    Achievement(
      id: 'streak_3',
      title: 'Threepeat',
      description: 'Answer on 3 days in a row.',
      tier: AchievementTier.bronze,
      qualifies: (p, _) => p.streak() >= 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Long',
      description: 'Keep a 7-day streak.',
      tier: AchievementTier.silver,
      qualifies: (p, _) => p.streak() >= 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Unbreakable',
      description: 'Keep a 30-day streak.',
      tier: AchievementTier.gold,
      qualifies: (p, _) => p.streak() >= 30,
    ),
    Achievement(
      id: 'sharp_eye',
      title: 'Sharp Eye',
      description: 'Answer 20+ cases at 90% accuracy or better.',
      tier: AchievementTier.silver,
      qualifies: (p, _) => p.totalAnswers >= 20 && (p.accuracy ?? 0) >= 90,
    ),
    Achievement(
      id: 'perfect_day',
      title: 'Perfect Drop',
      description: 'Get a whole day of cases right.',
      tier: AchievementTier.silver,
      qualifies: (p, _) => p.daily.values.any((s) => s.answers >= 4 && s.correct == s.answers),
    ),
    Achievement(
      id: 'field_master',
      title: 'Field Master',
      description: 'Collect 6 cards in a single arena.',
      tier: AchievementTier.silver,
      qualifies: (p, c) => c.fields.any((f) => p.countIn(f.id, c.cards) >= 6),
    ),
    Achievement(
      id: 'all_fields',
      title: 'Polymath',
      description: 'Collect 6 cards in every arena.',
      tier: AchievementTier.gold,
      qualifies: (p, c) => c.fields.every((f) => p.countIn(f.id, c.cards) >= 6),
    ),
    Achievement(
      id: 'legend_hunter',
      title: 'Legend Hunter',
      description: 'Collect 4 legendary cards.',
      tier: AchievementTier.gold,
      qualifies: (p, c) =>
          p.collected.keys.where((id) => c.cardOrNull(id)?.rarity.name == 'legendary').length >= 4,
    ),
    Achievement(
      id: 'xp_1000',
      title: 'Four Digits',
      description: 'Bank 1,000 XP.',
      tier: AchievementTier.silver,
      qualifies: (p, _) => p.xp >= 1000,
    ),
    Achievement(
      id: 'xp_5000',
      title: 'Heavyweight',
      description: 'Bank 5,000 XP.',
      tier: AchievementTier.gold,
      qualifies: (p, _) => p.xp >= 5000,
    ),
  ];

  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  static bool Function(PlayerProgress, GameCatalog) _hasCards(int n) =>
      (p, _) => p.collectedCount >= n;

  /// Badges earned by [progress] right now.
  static List<Achievement> unlockedFor(PlayerProgress progress, GameCatalog catalog) =>
      all.where((a) => a.qualifies(progress, catalog)).toList();

  /// Badges earned since [progress.unlockedAchievements] was last persisted.
  /// Returns the updated progress (with the new ids stamped) and the ids that
  /// were newly earned, so the UI can celebrate exactly the new ones.
  static (PlayerProgress, List<Achievement>) evaluate(
    PlayerProgress progress,
    GameCatalog catalog,
  ) {
    final earned = unlockedFor(progress, catalog);
    final known = progress.unlockedAchievements;
    final fresh = [for (final a in earned) if (!known.containsKey(a.id)) a];
    if (fresh.isEmpty) return (progress, const []);

    final now = DateTime.now();
    return (
      progress.copyWith(
        unlockedAchievements: {
          ...known,
          for (final a in fresh) a.id: now,
        },
      ),
      fresh,
    );
  }
}
