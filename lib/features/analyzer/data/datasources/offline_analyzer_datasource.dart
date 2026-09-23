import 'dart:math';

import '../models/analysis_model.dart';
import 'claude_analyzer_datasource.dart';

/// Rule-based analyzer that works without network or API key.
///
/// It looks for well known wording patterns of persuasion techniques. It is
/// less nuanced than Claude but gives an instant, private first read.
abstract interface class OfflineAnalyzerDataSource {
  RawAnalysis analyze(String text);
}

class _Rule {
  const _Rule(this.name, this.how, this.wants, this.weight, this.patterns);
  final String name;
  final String how;

  /// What the post wants from the reader, used to build the summary.
  final String wants;
  final int weight;
  final List<String> patterns;
}

class HeuristicAnalyzerDataSource implements OfflineAnalyzerDataSource {
  const HeuristicAnalyzerDataSource();

  static const _rules = [
    _Rule(
      'Savior Claim',
      'Casting one person as the only fix makes doubting them feel like siding with the problem.',
      'trust one person without question',
      9,
      [r"\bonly (i|we|he|she) can\b", r"\bi alone\b", r"\bno one else (can|will)\b", r"\bi'?m the only one\b"],
    ),
    _Rule(
      'Fear Appeal',
      'A vivid threat puts the brain in defense mode, where careful thinking takes a back seat.',
      'feel threatened',
      8,
      [
        r'\bchaos\b', r'\blos(e|ing) everything\b', r'\bdestroy', r'\bcrisis\b', r'\bdanger', r'\bthreat',
        r'\bafraid\b', r'\bcatastroph', r'\bcollapse', r'\bdisaster\b', r'\bscared?\b', r'\bwarning\b', r'\bnightmare\b',
      ],
    ),
    _Rule(
      'Us vs. Them',
      'Splitting the world into our side and theirs turns a claim into a loyalty test.',
      'pick a side',
      8,
      [
        r'\belites?\b', r'\bthe other side\b', r'\bthey want\b', r'\bthey don.?t want\b', r'\bpeople like (you|us)\b',
        r'\bfamilies like yours\b', r'\bhardworking\b', r'\bthe establishment\b', r'\breal (americans|people|patriots)\b',
        r'\btraitors?\b', r'\bwhile (they|the \w+) laugh', r'\benem(y|ies)\b',
      ],
    ),
    _Rule(
      'Scarcity',
      'Anything that seems about to run out instantly looks more valuable.',
      'grab it before it runs out',
      8,
      [
        r'\bonly \d+[\w,]* (left|spots?|seats?|places?|rooms?|pieces?|units?)\b', r'\b\d+ (spots?|seats?) left\b',
        r'\blimited\b', r'\bwhile supplies last\b', r'\brunning out\b', r'\bfew left\b', r'\blast chance\b', r'\bsold out\b',
      ],
    ),
    _Rule(
      'Urgency',
      'A deadline cuts off comparison: there is no time left to think it over.',
      'act before thinking',
      7,
      [
        r'\bright now\b', r'\btoday only\b', r'\bhurry\b', r"\bdon'?t wait\b", r'\bact (now|fast)\b', r'\bends (tonight|soon|today)\b',
        r'\blast day\b', r'\bbefore it.?s too late\b', r'\bnow or never\b', r'\bin the next \d+ (hours?|minutes?)\b', r'\bexpires?\b',
      ],
    ),
    _Rule(
      'Censorship Bait',
      '"They will delete this" makes a claim feel secret and true, and sharing it feel brave.',
      'share it without checking',
      7,
      [
        r'\bbefore (it|this) (gets|is) (taken down|deleted|banned|removed)\b', r"\bthey don.?t want you to (know|see)\b",
        r'\bbanned\b', r'\bcensored\b', r'\bshare (this|before|now)\b', r'\bwhat they.?re hiding\b',
      ],
    ),
    _Rule(
      'Social Proof',
      'When a crowd seems to be doing it, joining feels safe and staying out feels risky.',
      'follow the crowd',
      6,
      [
        r'\b\d[\d,.]*k?\+? (people|followers|members|customers|students|users)\b', r'\beveryone (is|has|knows)\b',
        r'\bjoin (thousands|millions)\b', r'\balready joined\b', r'\btrending\b', r'\bbest-?sell', r'\bmost popular\b',
      ],
    ),
    _Rule(
      'Too Good to Be True',
      'A dramatic before/after story sells the dream and skips the odds of actually getting there.',
      'buy into a dream',
      8,
      [
        r'\bi was broke\b', r'\bfrom broke\b', r'\$\s?\d[\d,.]*k? (a|per) (month|day|week)\b', r'\bpassive income\b',
        r'\bget rich\b', r'\bquit (my|your) job\b', r'\bfinancial freedom\b', r'\bfrom (my|your) phone\b', r'\bguaranteed\b',
        r'\bmillionaire\b', r'\bovernight\b',
      ],
    ),
    _Rule(
      'Guilt & Shame',
      'Making you feel bad about the status quo turns buying or agreeing into a way to stop feeling bad.',
      'feel bad about saying no',
      7,
      [
        r"\bif you'?re still\b", r"\byou'?re choosing\b", r'\bstay (broke|poor|average)\b', r"\bdon'?t you care\b",
        r'\bshame\b', r'\bloser\b', r'\bno excuses\b', r'\bwhat are you waiting for\b',
      ],
    ),
    _Rule(
      'Free Bait',
      '"Free" switches off cost-benefit thinking; the real price usually comes later.',
      'take the bait',
      4,
      [r'\bfree\b', r'\bno cost\b', r'\bbonus\b', r'\bgift\b'],
    ),
    _Rule(
      'Authority',
      'Symbols of expertise get us to accept a claim without checking the evidence.',
      'defer to a borrowed expert',
      5,
      [
        r'\bexperts? (say|agree)\b', r'\bdoctors?\b', r'\bscientists?\b', r'\bstudies (show|prove)\b', r'\bresearch (shows|proves)\b',
        r'\bcertified\b', r'\bclinically\b', r'\brecommend(ed)? by\b',
      ],
    ),
    _Rule(
      'Flattery',
      'Compliments lower our guard; we want to agree with people who see us the way we like.',
      'feel special enough to agree',
      4,
      [r'\bsmart people like you\b', r"\byou'?re one of the few\b", r'\byou deserve\b', r'\bonly the smartest\b', r'\bchosen\b'],
    ),
  ];

  @override
  RawAnalysis analyze(String text) {
    final src = text.trim();
    final found = <({_Rule rule, int hits, String quote})>[];

    for (final rule in _rules) {
      var hits = 0;
      String? quote;
      for (final p in rule.patterns) {
        final matches = RegExp(p, caseSensitive: false).allMatches(src).toList();
        if (matches.isEmpty) continue;
        hits += matches.length;
        quote ??= _quoteAround(src, matches.first);
      }
      if (hits > 0) found.add((rule: rule, hits: hits, quote: quote!));
    }

    int intensity(({_Rule rule, int hits, String quote}) f) {
      final score = f.rule.weight + (f.hits - 1) * 3;
      return score >= 10 ? 3 : score >= 7 ? 2 : 1;
    }

    found.sort((a, b) {
      final c = intensity(b).compareTo(intensity(a));
      return c != 0 ? c : (b.rule.weight * b.hits).compareTo(a.rule.weight * a.hits);
    });
    final top = found.take(4).toList();

    final exclaims = '!'.allMatches(src).length;
    final shouting = RegExp(r'\b[A-Z]{4,}\b').allMatches(src).length;
    var pressure = top.fold<int>(0, (s, f) => s + f.rule.weight * 2 + intensity(f) * 5) +
        min(exclaims, 5) * 2 +
        min(shouting, 5) * 3;
    if (top.isEmpty) pressure = min(pressure, 12);
    pressure = pressure.clamp(0, 100);

    return RawAnalysis(
      pressure: pressure,
      summary: _summary(top.map((f) => f.rule.wants).toList()),
      techniques: [
        for (final f in top) TechniqueModel(name: f.rule.name, quote: f.quote, how: f.rule.how, intensity: intensity(f)),
      ],
    );
  }

  String _summary(List<String> wants) {
    if (wants.isEmpty) return 'No obvious pressure tactics. It reads like it wants to inform, not push.';
    if (wants.length == 1) return 'It wants you to ${wants.first}.';
    return 'It wants you to ${wants[0]} and ${wants[1]}${wants.length > 2 ? ', fast' : ''}.';
  }

  /// Returns the words around [m], at most 12 words, trimmed to its sentence.
  String _quoteAround(String text, RegExpMatch m) {
    var start = text.lastIndexOf(RegExp(r'[.!?\n]'), max(0, m.start - 1));
    start = start < 0 ? 0 : start + 1;
    var end = text.indexOf(RegExp(r'[.!?\n]'), m.end);
    end = end < 0 ? text.length : end;
    final words = text.substring(start, end).trim().split(RegExp(r'\s+'));
    if (words.length <= 12) return words.join(' ');

    // Keep a 12-word window that contains the match.
    final before = text.substring(start, m.start).trim();
    final idx = before.isEmpty ? 0 : before.split(RegExp(r'\s+')).length;
    final from = max(0, min(idx - 3, words.length - 12));
    return '${from > 0 ? '…' : ''}${words.sublist(from, from + 12).join(' ')}…';
  }
}
