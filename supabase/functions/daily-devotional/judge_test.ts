// deno-lint-ignore-file require-await -- stubbed model calls stand in for async APIs
// Deterministic tests for the devotional quality gate. No network, no model:
// the parser, the pass/fail rule, the retry loop (driven by stubs), the
// index.ts wiring, and the eval fixtures themselves. The live-model evals are
// judge_eval_test.ts (opt-in).

import {
  buildJudgePrompt,
  callJudgeModel,
  generateWithJudge,
  JUDGE_CRITERIA,
  JUDGE_HARD_FAILS,
  JUDGE_PASS_THRESHOLD,
  type JudgeResult,
  overallScore,
  parseJudgeResponse,
  TRACK_INTENT,
} from "../_shared/devotional-judge.ts";
import { JUDGE_CASES } from "./evals/judge_cases.ts";
import bibleJson from "./bible.json" with { type: "json" };

function assert(cond: unknown, msg: string): asserts cond {
  if (!cond) throw new Error(msg);
}

function judgeJson(
  scores: Partial<Record<string, number>>,
  hard_fails: string[] = [],
  reasons: string[] = [],
): string {
  const full = Object.fromEntries(JUDGE_CRITERIA.map((c) => [c, scores[c] ?? 4]));
  return JSON.stringify({ scores: full, hard_fails, reasons });
}

const indexSource = () => Deno.readTextFileSync(new URL("./index.ts", import.meta.url));

// ─── Scoring ────────────────────────────────────────────────────────

Deno.test("overall maps all-1 to 0 and all-5 to 10", () => {
  const all = (n: number) => Object.fromEntries(JUDGE_CRITERIA.map((c) => [c, n])) as never;
  assert(overallScore(all(1)) === 0, `all-1 → ${overallScore(all(1))}`);
  assert(overallScore(all(5)) === 10, `all-5 → ${overallScore(all(5))}`);
  assert(overallScore(all(3)) === 5, `all-3 → ${overallScore(all(3))}`);
});

Deno.test("all-4s passes, all-3s fails", () => {
  assert(parseJudgeResponse(judgeJson({})).passed, "all 4s should pass");
  const threes = parseJudgeResponse(
    judgeJson(Object.fromEntries(JUDGE_CRITERIA.map((c) => [c, 3]))),
  );
  assert(!threes.passed, `all 3s should fail (overall ${threes.overall})`);
});

Deno.test("a single criterion at the floor fails even with a high average", () => {
  // The Numbers 26:58 shape: well-formed, on-track, but the verse can't carry it.
  const r = parseJudgeResponse(judgeJson({ verse_weight: 1, faithfulness: 5, substance: 5, track_fit: 5, craft: 5 }));
  assert(r.overall >= JUDGE_PASS_THRESHOLD, `precondition: overall ${r.overall} should clear threshold`);
  assert(!r.passed, "a floor-level criterion must fail the draft");
});

Deno.test("any hard fail fails a perfect score", () => {
  const all5 = Object.fromEntries(JUDGE_CRITERIA.map((c) => [c, 5]));
  const r = parseJudgeResponse(judgeJson(all5, ["misquoted_scripture"]));
  assert(!r.passed, "hard fail must fail");
  assert(r.hard_fails.length === 1, "hard fail kept");
});

Deno.test("verdict comes from scores, not from a verdict the model writes", () => {
  const ones = Object.fromEntries(JUDGE_CRITERIA.map((c) => [c, 1]));
  const r = parseJudgeResponse(JSON.stringify({ scores: ones, hard_fails: [], passed: true, verdict: "pass" }));
  assert(!r.passed, "model-written verdict must be ignored");
});

Deno.test("parser clamps, rounds, and drops unknown hard fails", () => {
  const r = parseJudgeResponse(
    judgeJson({ verse_weight: 9, faithfulness: 0, substance: 3.6 }, ["made_up", "broken_format", "broken_format"]),
  );
  assert(r.scores.verse_weight === 5, "clamped high");
  assert(r.scores.faithfulness === 1, "clamped low");
  assert(r.scores.substance === 4, "rounded");
  assert(JSON.stringify(r.hard_fails) === '["broken_format"]', `hard fails: ${r.hard_fails}`);
});

Deno.test("parser accepts numeric strings and fenced JSON", () => {
  const body = judgeJson({}).replace('"craft":4', '"craft":"5"');
  const r = parseJudgeResponse("```json\n" + body + "\n```");
  assert(r.scores.craft === 5, "string score parsed");
});

Deno.test("parser throws on missing scores so the caller fails open", () => {
  for (const bad of ["not json", "{}", JSON.stringify({ scores: { verse_weight: 4 } })]) {
    let threw = false;
    try {
      parseJudgeResponse(bad);
    } catch {
      threw = true;
    }
    assert(threw, `should throw on ${bad}`);
  }
});

// ─── Prompt ─────────────────────────────────────────────────────────

Deno.test("judge prompt carries the verse, the track's intent, and the draft", () => {
  const p = buildJudgePrompt({
    message: "DRAFT-BODY",
    track: "lament",
    verses: [{ book: "Psalms", chapter: 13, verse: 1, text: "How long wilt thou forget me, O LORD?" }],
    holidayName: "Good Friday",
  });
  for (const needle of ["DRAFT-BODY", "Psalms 13:1", "How long wilt thou forget me", "Deliberately does NOT resolve", "Good Friday", ...JUDGE_CRITERIA, ...JUDGE_HARD_FAILS]) {
    assert(p.includes(needle), `judge prompt missing: ${needle}`);
  }
});

Deno.test("every track in TRACK_CYCLE has a judge intent", () => {
  const m = indexSource().match(/const TRACK_CYCLE = \[([\s\S]*?)\] as const;/);
  assert(m, "TRACK_CYCLE not found");
  const tracks = [...m[1].matchAll(/"([^"]+)"/g)].map((x) => x[1]);
  assert(tracks.length > 0, "no tracks parsed");
  for (const t of tracks) assert(TRACK_INTENT[t], `TRACK_INTENT missing "${t}" — the judge would grade it generically`);
});

// ─── Model call ─────────────────────────────────────────────────────

Deno.test("callJudgeModel requests JSON from the given model", async () => {
  let sent: Record<string, unknown> = {};
  const fakeFetch = (async (_url: string, init: RequestInit) => {
    sent = JSON.parse(init.body as string);
    return new Response(JSON.stringify({ choices: [{ message: { content: judgeJson({}) } }], usage: { prompt_tokens: 10 } }));
  }) as unknown as typeof fetch;
  const { content, data } = await callJudgeModel({ apiKey: "k", model: "judge-x", prompt: "p", fetchFn: fakeFetch });
  assert(sent.model === "judge-x", "model passed through");
  assert((sent.response_format as { type: string }).type === "json_object", "json mode");
  assert(parseJudgeResponse(content).passed, "content returned");
  assert((data as { usage: { prompt_tokens: number } }).usage.prompt_tokens === 10, "raw data returned for costing");
});

Deno.test("callJudgeModel throws on HTTP error and empty content", async () => {
  for (const res of [new Response("boom", { status: 500 }), new Response(JSON.stringify({ choices: [] }))]) {
    const fakeFetch = (async () => res) as unknown as typeof fetch;
    let threw = false;
    try {
      await callJudgeModel({ apiKey: "k", model: "m", prompt: "p", fetchFn: fakeFetch });
    } catch {
      threw = true;
    }
    assert(threw, `should throw for status ${res.status}`);
  }
});

// ─── Retry loop ─────────────────────────────────────────────────────

const pass = (overall = 8): JudgeResult => ({
  version: "t", scores: Object.fromEntries(JUDGE_CRITERIA.map((c) => [c, 4])) as JudgeResult["scores"], overall, threshold: 7, hard_fails: [], passed: true, reasons: [],
});
const fail = (overall: number): JudgeResult => ({ ...pass(overall), passed: false });

// Drives generateWithJudge with verse-name candidates and a scripted judge.
async function run(script: Array<JudgeResult | Error>, maxAttempts = 3) {
  const verses = ["Numbers 26:58", "Psalms 13:1", "John 11:35", "Ruth 1:16"];
  const nextCalls: string[][] = [];
  let i = 0;
  const outcome = await generateWithJudge<string, { message: string }>({
    first: verses[0],
    next: async (tried) => {
      nextCalls.push([...tried]);
      return verses[tried.length];
    },
    generate: async (v) => ({ message: `devotional on ${v}` }),
    judge: async () => {
      const r = script[i++];
      if (r instanceof Error) throw r;
      return r;
    },
    maxAttempts,
    log: () => {},
  });
  assert(outcome.accepted, "script should produce a usable draft");
  return { outcome: { ...outcome, accepted: outcome.accepted }, nextCalls, judgeCalls: i };
}

Deno.test("first draft passes: published, nothing rejected, no retry", async () => {
  const { outcome, nextCalls } = await run([pass()]);
  assert(outcome.accepted.candidate === "Numbers 26:58", "first verse kept");
  assert(outcome.rejected.length === 0 && !outcome.exhausted, "nothing rejected");
  assert(nextCalls.length === 0, "no new verse requested");
});

Deno.test("failed draft is rejected and a different verse is tried", async () => {
  const { outcome, nextCalls } = await run([fail(4), pass()]);
  assert(outcome.accepted.candidate === "Psalms 13:1", `accepted ${outcome.accepted.candidate}`);
  assert(outcome.accepted.attempt === 2, "attempt number");
  assert(outcome.rejected.length === 1, "one rejection");
  assert(outcome.rejected[0].candidate === "Numbers 26:58", "the failed verse is the rejected one");
  assert(outcome.rejected[0].generation.message.includes("Numbers 26:58"), "rejected draft kept for the record");
  assert(JSON.stringify(nextCalls) === '[["Numbers 26:58"]]', `next() sees what was tried: ${JSON.stringify(nextCalls)}`);
  assert(!outcome.exhausted, "not exhausted");
});

Deno.test("stops at maxAttempts and publishes the best-scoring failure", async () => {
  const { outcome, judgeCalls } = await run([fail(3), fail(6.5), fail(5)]);
  assert(judgeCalls === 3, `judged ${judgeCalls} times`);
  assert(outcome.exhausted, "exhausted");
  assert(outcome.accepted.candidate === "Psalms 13:1", `best was attempt 2, got ${outcome.accepted.candidate}`);
  assert(outcome.rejected.length === 2, "the other two are rejected");
  assert(!outcome.rejected.includes(outcome.accepted), "published draft is never also recorded as rejected");
});

Deno.test("judge outage fails open: the draft is published unjudged", async () => {
  const { outcome, nextCalls } = await run([new Error("503")]);
  assert(outcome.accepted.judge === null, "no judge result");
  assert(outcome.accepted.judgeError === "503", "error kept for the row");
  assert(outcome.rejected.length === 0 && nextCalls.length === 0, "no retry on outage");
});

Deno.test("judge outage after a real fail keeps the earlier rejection", async () => {
  const { outcome } = await run([fail(4), new Error("timeout")]);
  assert(outcome.accepted.attempt === 2 && outcome.accepted.judge === null, "second draft published unjudged");
  assert(outcome.rejected.length === 1, "first draft still rejected");
});

Deno.test("generation errors propagate (handler returns 500 as before)", async () => {
  let threw = false;
  try {
    await generateWithJudge<string, string>({
      first: "a",
      next: async () => "b",
      generate: async () => {
        throw new Error("openai down");
      },
      judge: async () => pass(),
      log: () => {},
    });
  } catch (e) {
    threw = (e as Error).message === "openai down";
  }
  assert(threw, "generation error must propagate");
});

// ─── index.ts wiring (source checks; index.ts can't be imported) ────

Deno.test("JUDGE_MODEL is a single literal with no env fallback, priced", () => {
  const source = indexSource();
  const m = source.match(/const JUDGE_MODEL = "([^"]+)";/);
  assert(m, 'JUDGE_MODEL must be a single string literal: const JUDGE_MODEL = "...";');
  assert(!/JUDGE_MODEL\s*=\s*[\s\S]{0,40}Deno\.env\.get/.test(source), "JUDGE_MODEL must not read from env");
  assert(source.includes(`"${m[1]}":`), `MODEL_PRICING has no entry for ${m[1]}; judge cost would record as 0`);
});

Deno.test("handler gates generation through the judge and records rejections", () => {
  const source = indexSource();
  for (const marker of [
    "generateWithJudge<Candidate, Generation>",
    "judgeDraft(candidate, generation, track, holiday, signal)",
    "onFailedAttempt: (attempt) => recordRejections(",
    '.from("daily_devotional_rejections").insert(',
    "judge,\n", // saveDevotional persists the judge column
  ]) {
    assert(source.includes(marker), `index.ts missing: ${JSON.stringify(marker)}`);
  }
  // Rejections must be written before the published row, so a failed save
  // can't lose the record of why earlier drafts were thrown away.
  assert(
    source.indexOf("onFailedAttempt: (attempt) => recordRejections(") < source.indexOf("await saveDevotional("),
    "recordRejections must run before saveDevotional",
  );
});

Deno.test("retries keep track, type and testament; only the verse changes", () => {
  const source = indexSource();
  assert(
    source.includes("buildCandidate(devotionalType, targetTestament, track, holiday, formatted, tried, signal)"),
    "retry candidates must be built from the same devotionalType/targetTestament/track",
  );
});

Deno.test("migration creates the rejections table locked to service_role", () => {
  const dir = new URL("../../migrations/", import.meta.url);
  const file = [...Deno.readDirSync(dir)].map((e) => e.name).find((n) => n.endsWith("_add_devotional_judge.sql"));
  assert(file, "judge migration not found");
  const sql = Deno.readTextFileSync(new URL(file, dir));
  for (const needle of [
    'ADD COLUMN IF NOT EXISTS judge JSONB',
    "CREATE TABLE IF NOT EXISTS public.daily_devotional_rejections",
    "ENABLE ROW LEVEL SECURITY",
    "REVOKE ALL ON TABLE public.daily_devotional_rejections FROM anon",
  ]) {
    assert(sql.includes(needle), `migration missing: ${needle}`);
  }
});

// ─── Eval fixtures ──────────────────────────────────────────────────

Deno.test("eval cases: unique ids, both labels present, known tracks", () => {
  const ids = new Set(JUDGE_CASES.map((c) => c.id));
  assert(ids.size === JUDGE_CASES.length, "duplicate case id");
  assert(JUDGE_CASES.some((c) => c.expect === "pass"), "need at least one pass case");
  assert(JUDGE_CASES.some((c) => c.expect === "fail"), "need at least one fail case");
  for (const c of JUDGE_CASES) assert(TRACK_INTENT[c.track], `${c.id}: unknown track ${c.track}`);
});

Deno.test("eval cases quote exact KJV text", () => {
  // A fixture typo would teach the judge to flag misquotes that aren't there.
  const books = bibleJson as unknown as Array<{
    name: string;
    chapters: Array<{ number: number; paragraphs: Array<{ startingVerse: number; text: string }> }>;
  }>;
  for (const c of JUDGE_CASES) {
    for (const v of c.verses) {
      const para = books.find((b) => b.name === v.book)?.chapters.find((ch) => ch.number === v.chapter)
        ?.paragraphs.find((p) => p.startingVerse === v.verse);
      assert(para, `${c.id}: ${v.book} ${v.chapter}:${v.verse} not a paragraph start in bible.json`);
      const kjv = para.text.replace(/<\/?JESUS>/g, "").trim();
      assert(kjv === v.text, `${c.id}: verse text differs from bible.json\n  fixture: ${v.text}\n  kjv:     ${kjv}`);
    }
  }
});
