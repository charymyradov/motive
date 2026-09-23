enum Rarity {
  common(label: 'Common', tier: 1, xp: 40),
  rare(label: 'Rare', tier: 2, xp: 80),
  epic(label: 'Epic', tier: 3, xp: 150),
  legendary(label: 'Legendary', tier: 4, xp: 300);

  const Rarity({required this.label, required this.tier, required this.xp});

  final String label;

  /// 1..4, drawn as pips on the card.
  final int tier;

  /// XP earned when this card is unlocked.
  final int xp;
}
