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
