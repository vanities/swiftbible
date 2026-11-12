// Distribution tests for verse selection.
//
// These import and run the REAL production function. holidays_test.ts has to
// read index.ts as source text (it calls Deno.serve at top level) and so ends
// up reimplementing what it checks — which is how a live bug once survived a
// green suite. verse-selection.ts was extracted to _shared precisely so this
// file can exercise the actual code path.
import {
  eligibleParagraphs,
  isLamentCapable,
  lamentParagraphs,
  MAX_PARAGRAPH_CHARS,
  MIN_PARAGRAPH_CHARS,
  selectRandomVerse,
  UNSUITABLE_PATTERNS,
  unsuitableReason,
  type VerseBook,
} from "../_shared/verse-selection.ts";
import bibleJson from "./bible.json" with { type: "json" };

const books = bibleJson as unknown as VerseBook[];
const OT = books.slice(0, 39);
const NT = books.slice(39);

Deno.test("OT/NT split is the canonical 39/27", () => {
  if (OT.length !== 39 || NT.length !== 27) {
    throw new Error(`expected 39/27, got ${OT.length}/${NT.length}`);
  }
  if (OT[38].name !== "Malachi" || NT[0].name !== "Matthew") {
    throw new Error(`split is off: ...${OT[38].name} | ${NT[0].name}...`);
  }
});

Deno.test("selection is paragraph-weighted, not uniform-by-book", () => {
  // The regression this guards: uniform-by-book gave Psalms and Obadiah the
  // same 2.56% odds despite a 154x difference in material.
  const pool = eligibleParagraphs(OT, "old");
  const share = (name: string) =>
    pool.filter((v) => v.book === name).length / pool.length;

  const psalms = share("Psalms");
  const obadiah = share("Obadiah");
  const uniform = 1 / OT.length; // 2.56%

  if (psalms < 0.10) {
    throw new Error(
      `Psalms should hold >10% of the OT pool, got ${(psalms * 100).toFixed(2)}%` +
        " — selection has regressed to uniform-by-book"
    );
  }
  if (psalms < uniform * 3) {
    throw new Error(
      `Psalms (${(psalms * 100).toFixed(2)}%) should far exceed the uniform ` +
        `${(uniform * 100).toFixed(2)}%`
    );
  }
  if (obadiah >= psalms / 20) {
    throw new Error(
      `Obadiah (${(obadiah * 100).toFixed(2)}%) should be a small fraction of ` +
        `Psalms (${(psalms * 100).toFixed(2)}%)`
    );
  }
  // Nothing is banned — the short books must still be reachable.
  if (obadiah <= 0) throw new Error("Obadiah should still be selectable");
});

Deno.test("every eligible paragraph passes the length filters", () => {
  for (const t of ["old", "new"] as const) {
    for (const v of eligibleParagraphs(t === "old" ? OT : NT, t)) {
      if (v.text.trim().length < MIN_PARAGRAPH_CHARS) {
        throw new Error(`too short: ${v.book} ${v.chapter}:${v.verse}`);
      }
      if (v.text.length > MAX_PARAGRAPH_CHARS) {
        throw new Error(`too long: ${v.book} ${v.chapter}:${v.verse}`);
      }
    }
  }
});

Deno.test("no selected verse leaks <JESUS> red-letter markup", () => {
  for (const t of ["old", "new"] as const) {
    for (const v of eligibleParagraphs(t === "old" ? OT : NT, t)) {
      if (/<\/?JESUS>/.test(v.text)) {
        throw new Error(`markup leaked: ${v.book} ${v.chapter}:${v.verse}`);
      }
    }
  }
});

Deno.test("sampling the real function tracks the pool distribution", () => {
  const pool = eligibleParagraphs(NT, "new");
  const expected = pool.filter((v) => v.book === "Luke").length / pool.length;

  let luke = 0;
  const N = 20000;
  for (let i = 0; i < N; i++) {
    if (selectRandomVerse(NT, "new", "John").book === "Luke") luke++;
  }
  const observed = luke / N;
  // Generous band: this asserts the shape, not the RNG.
  if (Math.abs(observed - expected) > 0.03) {
    throw new Error(
      `Luke observed ${(observed * 100).toFixed(2)}% vs expected ` +
        `${(expected * 100).toFixed(2)}% — sampling is not pool-uniform`
    );
  }
  if (observed < 0.08) {
    throw new Error(
      `Luke at ${(observed * 100).toFixed(2)}% suggests uniform-by-book (3.7%)`
    );
  }
});

// ─── Unsuitable passage shapes ──────────────────────────────────────

const inPool = (pool: ReturnType<typeof eligibleParagraphs>, book: string, chapter: number, verse: number) =>
  pool.some((v) => v.book === book && v.chapter === chapter && v.verse === verse);

Deno.test("census, itinerary, begat and measurement passages never reach the pool", () => {
  const ot = eligibleParagraphs(OT, "old");
  const nt = eligibleParagraphs(NT, "new");
  const blocked: Array<[typeof ot, string, number, number, string]> = [
    [ot, "Numbers", 26, 58, "clan-list"], // 2026-10-11, the day that prompted this
    [ot, "Numbers", 33, 19, "itinerary"],
    [ot, "Genesis", 5, 18, "begat-chain"],
    [ot, "Exodus", 26, 16, "measurements"],
    [nt, "Acts", 7, 8, "begat-chain"],
  ];
  for (const [pool, book, ch, v, rule] of blocked) {
    if (inPool(pool, book, ch, v)) throw new Error(`${book} ${ch}:${v} (${rule}) should be filtered out`);
  }
});

Deno.test("passages a broader name/measure rule wrongly caught stay in the pool", () => {
  // The rejected "too many proper names" rule took every one of these, and
  // "talents" as a measurement took the parable. Keep the rules narrow.
  const nt = eligibleParagraphs(NT, "new");
  const kept: Array<[string, number, number]> = [
    ["John", 19, 19], // the title on the cross
    ["Mark", 15, 47], // Mary Magdalene sees where he was laid
    ["Matthew", 10, 2], // the twelve named
    ["Matthew", 25, 20], // parable of the talents
    ["John", 1, 40], // Andrew follows
  ];
  for (const [book, ch, v] of kept) {
    if (!inPool(nt, book, ch, v)) throw new Error(`${book} ${ch}:${v} should stay eligible`);
  }
  const ot = eligibleParagraphs(OT, "old");
  for (const [book, ch, v] of [["Psalms", 23, 1], ["Isaiah", 40, 30], ["Ruth", 1, 16]] as const) {
    if (!inPool(ot, book, ch, v)) throw new Error(`${book} ${ch}:${v} should stay eligible`);
  }
});

Deno.test("unsuitable rules stay narrow: under 1% of the pool, almost all OT", () => {
  // Measured at introduction: ~177 of ~24,000, one NT. A jump here means a
  // rule got broader and is now eating real devotional material.
  let ot = 0, nt = 0, total = 0;
  for (const [books, testament] of [[OT, "old"], [NT, "new"]] as const) {
    for (const b of books) for (const c of b.chapters) for (const p of c.paragraphs) {
      if (p.text.length > MAX_PARAGRAPH_CHARS || p.text.trim().length < MIN_PARAGRAPH_CHARS) continue;
      total++;
      if (unsuitableReason(p.text.replace(/<\/?JESUS>/g, ""))) testament === "old" ? ot++ : nt++;
    }
  }
  if ((ot + nt) / total > 0.01) throw new Error(`rules drop ${ot + nt}/${total} (>1%)`);
  if (nt > 3) throw new Error(`rules drop ${nt} NT paragraphs; expected ~1`);
});

Deno.test("each unsuitable rule has a sane minimum", () => {
  for (const r of UNSUITABLE_PATTERNS) {
    if (!r.pattern.global) throw new Error(`${r.name}: pattern must be /g so matches are counted`);
    if (r.min < 1) throw new Error(`${r.name}: min must be >= 1`);
  }
});

// ─── Lament pool ────────────────────────────────────────────────────

Deno.test("lament pool keeps passages that voice grief, loss or protest", () => {
  const ot = lamentParagraphs(OT, "old");
  const nt = lamentParagraphs(NT, "new");
  const kept: Array<[typeof ot, string, number, number]> = [
    [ot, "Psalms", 13, 1], // How long wilt thou forget me, O LORD?
    [ot, "Psalms", 22, 1], // why hast thou forsaken me?
    [ot, "Psalms", 137, 1], // By the rivers of Babylon ... we wept
    [ot, "Psalms", 42, 3], // My tears have been my meat
    [ot, "Lamentations", 1, 1],
    [ot, "Job", 3, 24], // my sighing cometh before I eat
    [ot, "Habakkuk", 1, 2], // O LORD, how long shall I cry
    [ot, "Ruth", 1, 19], // Call me Mara ... dealt very bitterly with me
    [ot, "2 Samuel", 18, 33], // O my son Absalom
    [ot, "Isaiah", 53, 3], // a man of sorrows, and acquainted with grief
    [nt, "Matthew", 27, 46], // Eli, Eli, lama sabachthani
    [nt, "Matthew", 26, 38], // My soul is exceeding sorrowful
    [nt, "Luke", 19, 41], // he beheld the city, and wept over it
    [nt, "Romans", 8, 22], // the whole creation groaneth
  ];
  for (const [pool, book, ch, v] of kept) {
    if (!inPool(pool, book, ch, v)) throw new Error(`${book} ${ch}:${v} should be in the lament pool`);
  }
});

Deno.test("lament pool drops the anchors the judge rejected for importing a loss", () => {
  // Every lament draft from 2026-10-29 to 2026-11-12 with track_fit <= 2
  // (daily_devotional_rejections). Each blanked a day.
  const ot = lamentParagraphs(OT, "old");
  const nt = lamentParagraphs(NT, "new");
  const rejected: Array<[typeof ot, string, number, number]> = [
    [ot, "Nahum", 1, 2], [ot, "Judges", 13, 8], [ot, "Psalms", 18, 37],
    [ot, "Psalms", 147, 5], [ot, "Numbers", 1, 20], [ot, "Genesis", 15, 11],
    [ot, "Isaiah", 6, 8], [ot, "Joshua", 1, 9], [ot, "Proverbs", 26, 1],
    [nt, "Ephesians", 2, 8], [nt, "Romans", 1, 17], [nt, "Hebrews", 4, 12],
    [nt, "Romans", 13, 7],
  ];
  for (const [pool, book, ch, v] of rejected) {
    if (inPool(pool, book, ch, v)) throw new Error(`${book} ${ch}:${v} carries no grief and should be excluded`);
  }
});

Deno.test("lament pool is a few percent of each testament, enough to rotate", () => {
  // Measured at introduction: 738/18000 OT (4.1%), 148/5829 NT (2.5%). Too
  // small and the track repeats verses; too large and the filter has stopped
  // filtering.
  for (const [books, testament, lo, hi] of [[OT, "old", 0.02, 0.08], [NT, "new", 0.01, 0.06]] as const) {
    const all = eligibleParagraphs(books, testament).length;
    const lament = lamentParagraphs(books, testament).length;
    const share = lament / all;
    if (share < lo || share > hi) {
      throw new Error(`${testament} lament pool ${lament}/${all} (${(share * 100).toFixed(1)}%) outside ${lo * 100}-${hi * 100}%`);
    }
    if (lament < 100) throw new Error(`${testament} lament pool has only ${lament} passages`);
  }
});

Deno.test("lament selection only draws from the lament pool", () => {
  for (const [books, testament, fallback] of [[OT, "old", "Psalms"], [NT, "new", "John"]] as const) {
    for (let i = 0; i < 2000; i++) {
      const v = selectRandomVerse(books, testament, fallback, new Set(), { lament: true });
      if (!isLamentCapable(v.text)) throw new Error(`drew ${v.book} ${v.chapter}:${v.verse}, which carries no grief`);
    }
  }
});

Deno.test("lament words match whole words, case-insensitively", () => {
  const yes = ["How long, O LORD?", "Jesus wept.", "and SORROW and sighing", "why hast thou forsaken me"];
  const no = ["he received his sight", "his commandments are not grievous", "a cry of joy", "Let not your heart be troubled"];
  for (const s of yes) if (!isLamentCapable(s)) throw new Error(`should match: ${s}`);
  for (const s of no) if (isLamentCapable(s)) throw new Error(`should not match: ${s}`);
});
