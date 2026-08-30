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
// census lists. Applied once when the index is built, not per attempt.
export const MIN_PARAGRAPH_CHARS = 20;
export const MAX_PARAGRAPH_CHARS = 400;

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
        out.push({
          book: book.name,
          chapter: chapter.number,
          verse: paragraph.startingVerse,
          text: stripJesusTags(paragraph.text),
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
