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

export function selectRandomVerse(
  books: VerseBook[],
  testament: "old" | "new",
  fallbackBookName: string
): SelectedVerse {
  const pool = eligibleParagraphs(books, testament);
  if (pool.length > 0) {
    return pool[Math.floor(Math.random() * pool.length)];
  }

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
