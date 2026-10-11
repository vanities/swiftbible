// Distribution tests for verse selection.
//
// These import and run the REAL production function. holidays_test.ts has to
// read index.ts as source text (it calls Deno.serve at top level) and so ends
// up reimplementing what it checks — which is how a live bug once survived a
// green suite. verse-selection.ts was extracted to _shared precisely so this
// file can exercise the actual code path.
import {
  eligibleParagraphs,
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
