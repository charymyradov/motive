import 'package:flutter_test/flutter_test.dart';
import 'package:motive/features/analyzer/data/datasources/offline_analyzer_datasource.dart';

void main() {
  const engine = HeuristicAnalyzerDataSource();

  test('spots the levers in a manipulative political post', () {
    final r = engine.analyze(
      "Only I can stop the chaos. Every single day, hardworking families like yours are losing everything while "
      "the elites laugh at you. The other side wants you afraid and silent. Don't let them win. "
      'Share this before it gets taken down.',
    );
    final names = r.techniques.map((t) => t.name).toList();
    expect(r.pressure, greaterThan(60));
    expect(names, containsAll(['Us vs. Them', 'Fear Appeal']));
    expect(r.techniques.length, lessThanOrEqualTo(4));
    for (final t in r.techniques) {
      expect(t.quote.split(' ').length, lessThanOrEqualTo(13));
      expect(t.intensity, inInclusiveRange(1, 3));
    }
  });

  test('spots the levers in an influencer promo', () {
    final r = engine.analyze(
      "I was broke 12 months ago. Now I make \$30K a month from my phone. Only 50 spots left in my FREE masterclass, "
      "and 4,000 people already joined. If you're still scrolling, you're choosing to stay broke.",
    );
    final names = r.techniques.map((t) => t.name).toSet();
    expect(names, contains('Too Good to Be True'));
    expect(names.intersection({'Scarcity', 'Guilt & Shame', 'Social Proof'}), isNotEmpty);
  });

  test('a neutral post gets a low score and no techniques', () {
    final r = engine.analyze('The library will be closed on Monday for maintenance. Regular hours resume Tuesday.');
    expect(r.techniques, isEmpty);
    expect(r.pressure, lessThan(15));
  });
}
