// Random verse selection for the daily devotional.
//
// Lives in _shared and takes its data as a parameter so it is importable and
// testable. daily-devotional/index.ts cannot be imported by a test — it calls
// Deno.serve at top level — which is why holidays_test.ts historically
// reimplemented the helpers it checked, and why a live bug once survived a
// green suite. Anything with real logic belongs here instead.
//
// WEIGHTING. The original implementation picked a uniformly random BOOK, then
// a random chapter, then a random paragraph. Every book therefore drew equally
// regardless of size: in the OT, Psalms (150 chapters, 2461 paragraphs) and
// Obadiah (1 chapter, 16 paragraphs) both drew 2.56% of the time. The daily
// anchors showed it — "Pekahiah began to reign" (2 Kings 15:23), palace
// joinery (1 Kings 7:7) — and there were zero Psalms anchors in the 53 days to
// 2026-08-30, against ~0.67 expected. That was the sampling design, not luck.
//
// Sampling uniformly over eligible PARAGRAPHS weights each book by the amount
// of usable material it actually holds — Psalms 2.56% -> ~13.5%, Luke
// 3.70% -> ~14.7% — while banning nothing. Obadiah still comes up, just at a
// rate proportional to its length.

export interface SelectedVerse {
  book: string;
  chapter: number;
  verse: number;
  text: string;
  testament: "old" | "new";
}

export interface VerseBook {
  name: string;
  chapters: Array<{
    number: number;
    paragraphs: Array<{ startingVerse: number; text: string }>;
  }>;
}

export function verseKey(v: { book: string; chapter: number; verse: number }): string {
  return `${v.book} ${v.chapter}:${v.verse}`;
}

// Paragraphs shorter than this are fragments; longer ones are genealogies and
// census lists (short ones are caught by UNSUITABLE_PATTERNS below). Applied
// once when the index is built, not per attempt.
export const MIN_PARAGRAPH_CHARS = 20;
export const MAX_PARAGRAPH_CHARS = 400;

// Passage shapes that cannot carry a devotional however well it is written.
// Checked before generation so a census line never costs a generation plus a
// judge round (the 2026-10-11 Numbers 26:58 lament was one). The judge after
// generation stays the backstop for everything a pattern cannot see.
//
// Deliberately narrow. Each rule matches one structural shape, and was
// measured against the whole pool: together they drop ~177 of ~24,000
// eligible paragraphs, all but one OT (Acts 7:8, a begat recap). A broader
// "too many proper names" rule was tried and rejected: it took the cross's
// title (John 19:19), Mary Magdalene at the tomb (Mark 15:47) and the calling
// of the twelve (Matthew 10:2). A missed bad verse costs one retry; a blocked
// good one costs nothing visible only while the rules stay this narrow.
//
// Add a rule when daily_devotional_rejections shows a recurring shape the
// judge fails for verse_weight, and add the case to verse_selection_test.ts.
export const UNSUITABLE_PATTERNS: Array<{ name: string; pattern: RegExp; min: number }> = [
  // "And Attai begat Nathan, and Nathan begat Zabad…"
  { name: "begat-chain", pattern: /\bbegat\b/g, min: 2 },
  // "And they departed from Rithmah, and pitched at Rimmonparez."
  {
    name: "itinerary",
    pattern: /\b(?:departed|removed|journeyed|went) from [A-Z][\w-]*,? and (?:pitched|encamped)\b/g,
    min: 1,
  },
  // "the family of the Libnites, the family of the Hebronites…"
  { name: "clan-list", pattern: /\bthe family of the \w+ites\b/g, min: 2 },
  // Tabernacle/temple specifications. No "talents": that word is the parable.
  {
    name: "measurements",
    pattern:
      /\b(?:cubits?|sockets?|boards?|bars|basons|breadth|shekels?|tenons|loops|taches|ouches|chapiters|pomegranates)\b/g,
    min: 3,
  },
];

export function unsuitableReason(text: string): string | null {
  for (const rule of UNSUITABLE_PATTERNS) {
    if ((text.match(rule.pattern)?.length ?? 0) >= rule.min) return rule.name;
  }
  return null;
}

// The lament track can only be written on a passage that itself mourns, fears
// or protests. Drawn from the whole pool, almost every anchor had none: 15 of
// the 16 lament drafts judged between 2026-10-29 and 2026-11-12 failed, 13 of
// them with track_fit <= 2 for importing a loss the verse does not name (Nahum 1:2,
// Numbers 1:20, Psalms 147:5, Isaiah 6:8...). A failed day saves no row, so
// the rotation chose lament again the next day and the devotional went blank
// for days at a time.
//
// The vocabulary is the KJV's own words for grief and complaint. Measured at
// introduction: ~4% of the OT pool and ~2.5% of the NT pool, and it keeps the
// classic laments (Psalms 13:1, 22:1, 137:1, Lamentations 1, Matthew 27:46).
// It also keeps judgment oracles ("the land shall be desolate"): the judge
// scored a curse passage as real loss (Deuteronomy 28:49, track_fit 5).
// Deliberately not here: "cry" (praise and proclamation), "grievous" ("his
// commandments are not grievous"), "died"/"dead" (genealogies, resurrection),
// "trouble" ("let not your heart be troubled"). The judge stays the backstop.
const LAMENT_WORDS = [
  "wept", "weep(?:est|eth|ing)?",
  "mourn(?:ed|est|eth|ing|ers?)?",
  "tears",
  "sorrow(?:s|ed|est|eth|ful|ing)?",
  "grie(?:f|fs|ve|ved|vest|veth|ving)",
  "lament(?:ed|ing|ation|ations)?",
  "wail(?:ed|ing)?", "howl(?:ed|ing)?",
  "groan(?:ed|eth|ing|ings)?",
  "sigh(?:ed|est|eth|ing|s)?",
  "anguish", "bitterly", "sackcloth",
  "bereave(?:d|th)?", "desolate", "forsaken",
  "afflict(?:ed|ion|ions)",
  // Protest addressed to God: "How long, O LORD?", "why hast thou forsaken me?"
  "woe is me", "how long", "why hast thou", "why art thou",
  "why standest thou", "wherefore hast thou", "hidest thou",
];
export const LAMENT_PATTERN = new RegExp(`\\b(?:${LAMENT_WORDS.join("|")})\\b`, "i");

export function isLamentCapable(text: string): boolean {
  return LAMENT_PATTERN.test(text);
}

function stripJesusTags(text: string): string {
  return text.replace(/<\/?JESUS>/g, "").trim();
}

// Keyed on the book array itself, so a test can build its own pool without
// poisoning the cache the function uses in production.
const poolCache = new WeakMap<object, SelectedVerse[]>();

export function eligibleParagraphs(
  books: VerseBook[],
  testament: "old" | "new"
): SelectedVerse[] {
  const cached = poolCache.get(books);
  if (cached) return cached;

  const out: SelectedVerse[] = [];
  for (const book of books) {
    for (const chapter of book.chapters) {
      for (const paragraph of chapter.paragraphs) {
        if (paragraph.text.length > MAX_PARAGRAPH_CHARS) continue;
        if (paragraph.text.trim().length < MIN_PARAGRAPH_CHARS) continue;
        const text = stripJesusTags(paragraph.text);
        if (unsuitableReason(text)) continue;
        out.push({
          book: book.name,
          chapter: chapter.number,
          verse: paragraph.startingVerse,
          text,
          testament,
        });
      }
    }
  }
  poolCache.set(books, out);
  return out;
}

const lamentPoolCache = new WeakMap<object, SelectedVerse[]>();

// The eligible pool narrowed to passages that voice grief, loss or protest.
export function lamentParagraphs(
  books: VerseBook[],
  testament: "old" | "new"
): SelectedVerse[] {
  const cached = lamentPoolCache.get(books);
  if (cached) return cached;
  const out = eligibleParagraphs(books, testament).filter((v) => isLamentCapable(v.text));
  lamentPoolCache.set(books, out);
  return out;
}

export function selectRandomVerse(
  books: VerseBook[],
  testament: "old" | "new",
  fallbackBookName: string,
  excluded: ReadonlySet<string> = new Set(),
  opts: { lament?: boolean } = {},
): SelectedVerse {
  const eligible = opts.lament
    ? lamentParagraphs(books, testament)
    : eligibleParagraphs(books, testament);
  const pool = excluded.size ? eligible.filter((v) => !excluded.has(verseKey(v))) : eligible;
  if (pool.length > 0) {
    return pool[Math.floor(Math.random() * pool.length)];
  }
  if (eligible.length) throw new Error("verse selection: no unused eligible passages remain");

  // Unreachable unless the bundled text failed to load.
  const fallbackBook = books.find((b) => b.name === fallbackBookName);
  if (!fallbackBook) {
    throw new Error(
      `verse selection: empty pool and no fallback book "${fallbackBookName}"`
    );
  }
  const chapter =
    fallbackBook.chapters[
      Math.floor(Math.random() * fallbackBook.chapters.length)
    ];
  const paragraph =
    chapter.paragraphs[Math.floor(Math.random() * chapter.paragraphs.length)];
  return {
    book: fallbackBook.name,
    chapter: chapter.number,
    verse: paragraph.startingVerse,
    text: stripJesusTags(paragraph.text),
    testament,
  };
}
