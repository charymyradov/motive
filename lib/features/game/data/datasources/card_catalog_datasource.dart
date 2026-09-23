import '../../domain/entities/game_catalog.dart';
import '../../domain/entities/motive_card.dart';
import '../../domain/entities/psych_field.dart';
import '../../domain/entities/rarity.dart';

/// Bundled game content. Kept in code so the game works fully offline; it
/// could be swapped for a remote source without touching the domain.
abstract interface class CardCatalogDataSource {
  GameCatalog load();
}

class BundledCardCatalogDataSource implements CardCatalogDataSource {
  const BundledCardCatalogDataSource();

  static final GameCatalog _catalog = GameCatalog(fields: _fields, cards: _cards);

  @override
  GameCatalog load() => _catalog;
}

const _fields = [
  PsychField(id: 'rc', name: 'Relationship Coach', short: 'Love', description: 'Why people stay, leave, and fight about the dishes.'),
  PsychField(id: 'ms', name: 'Media Skeptic', short: 'Media', description: 'Headlines, feeds and the lies that feel true.'),
  PsychField(id: 'mm', name: 'Money Mind', short: 'Money', description: 'Prices, deals and the urge to buy right now.'),
  PsychField(id: 'ng', name: 'Negotiator', short: 'Influence', description: 'Favors, crowds and the quiet art of the yes.'),
];

MotiveCard _k(
  String id,
  String no,
  String field,
  Rarity rarity,
  String force,
  String question,
  String why,
  String text,
  String hypothesis,
  bool holds,
) =>
    MotiveCard(
      id: id,
      number: no,
      fieldId: field,
      rarity: rarity,
      force: force,
      question: question,
      why: why,
      scenario: CaseScenario(text: text, hypothesis: hypothesis, holds: holds),
    );

final _cards = [
  // ── Relationship Coach ─────────────────────────────────────────────
  _k('rc1', '01', 'rc', Rarity.epic, 'Sunk Cost Fallacy',
      'Why do we stay in relationships we already know are over?',
      'The years are gone either way. Leaving makes the loss visible, so staying feels like a way to avoid it.',
      'Maya has been unhappy for two years. "We\'ve been together six," she tells a friend. "I can\'t just throw that away."',
      'She stays because the years already spent would feel wasted if she left.', true),
  _k('rc2', '02', 'rc', Rarity.common, 'Negativity Bias',
      'Why does one late reply outweigh ten sweet messages?',
      'Threats mattered more for survival than pleasures, so the brain weighs bad moments heavier. One sting needs several kind moments to balance it.',
      "Your partner sent ten warm texts this week. On Thursday they took five hours to answer one. That's the one you keep replaying at night.",
      'Bad moments weigh more on the mind than good ones of the same size.', true),
  _k('rc3', '03', 'rc', Rarity.rare, 'Displacement',
      "Why do couples fight about the dishes when it's about something else?",
      'Unspoken needs get routed into safer, smaller arguments. The dishes are easier to fight about than feeling unseen.',
      "Jordan snaps at his partner for leaving a mug in the sink. Later that night he admits he's felt ignored since she started her new job.",
      'The fight was really about the mug being left out.', false),
  _k('rc4', '04', 'rc', Rarity.common, 'Rosy Retrospection',
      'Why does your ex look better a year after the breakup?',
      'Memory keeps the highlights and drops the daily friction. The past gets edited in its own favor.',
      'A year after the breakup, Priya scrolls old photos and sighs, "We were so happy." Her journal from that year is mostly about arguments.',
      'Her memory quietly kept the highlights and dropped the daily friction.', true),
  _k('rc5', '05', 'rc', Rarity.legendary, 'Intermittent Reinforcement',
      'Why do we chase the people who ignore us?',
      'Rewards that arrive unpredictably hook us harder than reliable ones. Hot-and-cold attention works like a slot machine: the next pull might pay out.',
      'Some days Dan replies to Kim within seconds. Other times he vanishes for three days. She checks her phone constantly and feels a rush every time his name lights up.',
      "She's hooked because the attention is unpredictable, not in spite of it.", true),
  _k('rc6', '06', 'rc', Rarity.rare, 'Illusion of Transparency',
      'Why do we assume our partner knows what we meant?',
      'We overestimate how clearly our inner state shows. The hint felt loud from the inside; from the outside it was barely there.',
      'Sam sighs twice while folding laundry and says "it\'s fine." Later: "You should have known I wanted help." Their partner had no idea anything was wrong.',
      'The partner saw the obvious signals and ignored them on purpose.', false),

  // ── Media Skeptic ──────────────────────────────────────────────────
  _k('ms1', '07', 'ms', Rarity.rare, 'Dunning–Kruger Effect',
      'Why are beginners more confident than experts?',
      'Spotting mistakes takes the same skill as avoiding them. Beginners lack both, so their confidence has nothing to check it.',
      "After three YouTube videos on investing, Sam tells his family he'd beat most fund managers. His uncle, a trader for twenty years, says he still isn't sure what the market will do.",
      "Sam is confident because he doesn't know enough to see his own blind spots.", true),
  _k('ms2', '08', 'ms', Rarity.epic, 'Illusory Truth Effect',
      'Why does a lie feel truer the tenth time you hear it?',
      'Repetition makes a claim easier to process, and the brain mistakes easy for true. Five reposts are not five sources.',
      'A claim about a "banned" food additive shows up from five different accounts in one week. You never checked it. You\'ve quietly stopped buying the product.',
      'Five accounts saying it means someone has probably verified it.', false),
  _k('ms3', '09', 'ms', Rarity.epic, 'Moral Contagion',
      'Why does outrage spread faster than good news?',
      'Outrage grabs attention and signals loyalty to your group, so feeds reward it with reach.',
      'The same news page posts a heartwarming rescue story and an angry post about a politician. By evening the angry post has forty times the shares.',
      "People share outrage because it grabs attention and shows whose side they're on.", true),
  _k('ms4', '10', 'ms', Rarity.common, 'Confirmation Bias',
      'Why do you only notice posts that agree with you?',
      'We search for, notice and remember what fits what we already believe. Everything else slides past unnoticed.',
      'Rosa is sure her city is getting more dangerous. She remembers every crime story in her feed and scrolls right past the report showing crime fell 8% this year.',
      "She's simply better informed than the report.", false),
  _k('ms5', '11', 'ms', Rarity.rare, 'Authority Bias',
      'Why does a white coat make an ad more convincing?',
      'Symbols of expertise switch off our own judgment. The coat is doing the persuading, not the evidence.',
      'A toothpaste ad shows an actor in a white coat: "9 out of 10 dentists recommend." You buy it without noticing the survey let dentists pick several brands.',
      'The white coat made the claim feel checked, even though nothing was.', true),
  _k('ms6', '12', 'ms', Rarity.common, 'Curiosity Gap',
      "Why can't you ignore a headline that ends with a question?",
      'An open question creates a small itch of missing information. The headline sells the scratch.',
      '"She opened the door and couldn\'t believe what she saw..." You tap, wade through four paragraphs of ads, and learn it was a surprise party.',
      'You clicked because the story was genuinely important news.', false),

  // ── Money Mind ─────────────────────────────────────────────────────
  _k('mm1', '13', 'mm', Rarity.common, 'Anchoring',
      'Why does a \$2,000 sofa make a \$400 lamp feel cheap?',
      'The first number you see becomes the ruler for every number after it. Next to \$2,000, \$400 looked small.',
      'Lena walks in planning to spend \$100 on a lamp. The first thing she sees is a \$2,000 sofa. She leaves with a \$400 lamp, pleased she found a deal.',
      'The \$400 lamp was simply better quality, and she recognized it.', false),
  _k('mm2', '14', 'mm', Rarity.legendary, 'Scarcity & Urgency',
      'Why does "only 2 left" make your heart race?',
      'Scarcity signals value, and a deadline cuts off comparison. The countdown exists to stop you from thinking.',
      '"Only 2 rooms left at this price. 14 people are looking right now." You book in under a minute, without opening a single other site.',
      'You booked fast because it was objectively the best deal available.', false),
  _k('mm3', '15', 'mm', Rarity.rare, 'Loss Aversion',
      'Why does losing \$50 hurt more than finding \$50 feels good?',
      'Losses land roughly twice as hard as equal gains. The mind is built to guard, not to gain.',
      'A gym tests two emails: "Get \$50 off if you join today" and "Lose your \$50 discount if you don\'t join today." The second one doubles sign-ups.',
      'Framing it as a loss made the same \$50 feel bigger.', true),
  _k('mm4', '16', 'mm', Rarity.common, 'Zero-Price Effect',
      'Why does "free shipping over \$40" make you spend \$45?',
      '"Free" isn\'t just a low price, it switches off our cost-benefit math. We\'ll pay real money to reach a zero.',
      'Your cart is \$32. Shipping costs \$5, or nothing over \$40. You add an \$11 phone case you didn\'t need and feel like you saved money.',
      'Adding the case to get free shipping saved you money.', false),
  _k('mm5', '17', 'mm', Rarity.epic, 'Pain of Paying',
      'Why do you spend more with a card than with cash?',
      'Handing over cash hurts; tapping a card barely registers. Less pain means less brake on spending.',
      "Tom spends about \$40 on a night out when he pays cash. On nights he taps his card, it's \$68 on average, and he can't say where it went.",
      'Paying by card blunts the sting of spending, so he spends more.', true),
  _k('mm6', '18', 'mm', Rarity.common, 'Left-Digit Bias',
      'Why does \$9.99 feel so much cheaper than \$10?',
      'We read prices left to right and anchor on the first digit. \$9.99 lands in the "nine" box, \$10 in the "ten" box.',
      'A café changes its sandwich price from \$5.00 to \$4.95. Sales jump by a fifth, though nobody would say five cents matters to them.',
      'Customers read the first digit and filed the price as "four-something."', true),

  // ── Negotiator ─────────────────────────────────────────────────────
  _k('ng1', '19', 'ng', Rarity.rare, 'Reciprocity',
      'Why does a small free gift make you buy more?',
      'Humans are wired to return favors. Even a tiny gift you never asked for creates pressure to give something back.',
      'At the market, a vendor hands you a free slice of cheese and chats for a minute. You had no plan to buy cheese. You walk away with a €14 wedge.',
      'You felt a quiet debt and paid it back with a purchase.', true),
  _k('ng2', '20', 'ng', Rarity.epic, 'Social Proof',
      'Why does "everyone on your team signed up" work so well?',
      'When unsure, we copy the crowd. "Nine of ten" tells you what normal looks like, and breaking from normal feels risky.',
      'Your manager emails: "Nine of your ten teammates have already signed up for Saturday\'s workshop." You weren\'t planning to go. You sign up before lunch.',
      'You signed up because the workshop itself sounded useful.', false),
  _k('ng3', '21', 'ng', Rarity.rare, 'Foot-in-the-Door',
      'Why does a small yes lead to a big yes?',
      'Saying yes once shapes how you see yourself. Refusing the bigger ask would feel inconsistent.',
      "A volunteer asks you to sign a petition for safer streets. A week later they ask you to put a big sign in your yard. You agree, though you'd have refused if that had been the first ask.",
      'You agreed because putting up a sign is a small request.', false),
  _k('ng4', '22', 'ng', Rarity.epic, 'First-Offer Anchor',
      'Why does the first number on the table shape the whole deal?',
      'The first number becomes the reference point for every counter. Both sides adjust from it, and rarely far enough.',
      'You list your used car, worth about \$7,000. A buyer opens at \$4,000. After some haggling you settle at \$5,500 and feel like you won.',
      '\$5,500 was a fair middle ground based on what the car is worth.', false),
  _k('ng5', '23', 'ng', Rarity.common, 'Liking Principle',
      'Why do we say yes to people we like, even when the offer is bad?',
      'We want to agree with people we like, and we like people who seem similar, friendly or complimentary. The offer gets graded on the person.',
      "The salesperson went to your university, loves your dog and remembers your name. You sign up for the premium plan you'd planned to decline.",
      'Liking the person made the offer look better than it was.', true),
  _k('ng6', '24', 'ng', Rarity.legendary, 'But-You-Are-Free',
      'Why does "of course, you\'re free to say no" make people say yes?',
      'Reminding people they can refuse lowers their defenses. Feeling free makes yes feel like your own choice.',
      'A street fundraiser asks for a donation, then adds: "Of course, you\'re totally free to say no." Studies find that one line roughly doubles how often people give.',
      'Reassuring people they can refuse makes them more likely to agree.', true),
];
