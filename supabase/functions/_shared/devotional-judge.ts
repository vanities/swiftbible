// Quality gate for the daily devotional.
//
// After a devotional is generated and before it is saved, a second model call
// grades it against a fixed rubric. Below the threshold (or on any hard fail)
// the failed judgment is recorded in daily_devotional_rejections;
// the function regenerates on the same track, type and testament from a
// different verse.
//
// Lives in _shared for the same reason verse-selection.ts does:
// daily-devotional/index.ts calls Deno.serve at top level and cannot be
// imported by a test. Everything with logic (prompt, parsing, pass/fail, the
// retry loop) is here and exercised by daily-devotional/judge_test.ts; the
// live-model evals are daily-devotional/judge_eval_test.ts.
//
// The model id is NOT set here. JUDGE_MODEL lives beside DEVOTIONAL_MODEL in
// daily-devotional/index.ts (one source of truth for every model) and is
// passed in.
//
// Pass/fail is decided in code from the per-criterion scores, never from a
// verdict the model writes. A model asked "pass or fail?" drifts toward pass;
// asked for scores against anchored descriptions, it is far steadier, and the
// threshold stays a number we can tune and test.

import { PROMPT_THEOLOGY_GUARDRAILS } from "./devotional-voice.ts";

// Bump when the rubric or prompt changes, so judge results stored on rows can
// be compared like with like (mirrors prompt_version on the devotional).
export const JUDGE_PROMPT_VERSION = "judge-v1";

// Overall score is the weighted mean of the criteria, scaled to 0–10.
// 7.0 means "solidly good on average, nothing weak enough to drag it down".
// Tune against judge_eval_test.ts, not by feel.
export const JUDGE_PASS_THRESHOLD = 7.0;

// Any single criterion at or below this fails the draft regardless of the
// average. A devotional that is beautifully written about a verse that cannot
// carry it is still a bad devotional.
export const JUDGE_CRITERION_FLOOR = 2;

// Total generations per day, including the first. Each attempt is one
// generation (~20–60s) plus one judge call, and the Edge Function has a wall
// clock limit, so keep this small.
export const JUDGE_MAX_ATTEMPTS = 3;

// Leave 30 seconds below Supabase's 150-second request timeout for audit,
// persistence and error reporting. All model calls share this deadline.
export const GENERATION_BUDGET_MS = 120_000;

export const JUDGE_CRITERIA = [
  "verse_weight",
  "faithfulness",
  "substance",
  "track_fit",
  "craft",
] as const;
export type JudgeCriterion = typeof JUDGE_CRITERIA[number];

// faithfulness and verse_weight carry the most: a misread text or a verse
// stretched past what it says is the failure readers notice and distrust.
export const JUDGE_WEIGHTS: Record<JudgeCriterion, number> = {
  verse_weight: 1.5,
  faithfulness: 1.5,
  substance: 1.0,
  track_fit: 1.0,
  craft: 0.75,
};

export const JUDGE_HARD_FAILS = [
  "misquoted_scripture",
  "factual_error",
  "theological_error",
  "verse_cannot_carry_devotional",
  "broken_format",
  "inappropriate_content",
] as const;
export type JudgeHardFail = typeof JUDGE_HARD_FAILS[number];

// What each track is FOR, so the judge grades it on its own terms. Without
// this the lament track (which deliberately does not resolve) is marked down
// for not resolving, and the matt track for being terse.
export const TRACK_INTENT: Record<string, string> = {
  empathy:
    "Four beats: an observable opening scene, what the verse actually says (one short Hebrew/Greek note at most), bringing the two together honestly, then a short prayer. Quiet pastoral warmth.",
  technical:
    "Contextual, historical, cultural and linguistic study of the verse, then reflection questions and an italic closing meditation. Heavier on biblical background than modern application.",
  narrative:
    "Retells the scene in the text vividly without inventing dialogue, motives or events scripture does not supply, then lands on the reader.",
  practical:
    "Draws one concrete action from the verse, names how it typically goes wrong, and what the text says to do then.",
  matt:
    "Terse, dry, precise on the text. Concrete domestic opening, a close reading of which words carry the weight, then a few short imperatives. Spare by design; do not mark it down for brevity.",
  josh:
    "Teacher's register. Opens on a real question, sets the text in its original world with honest uncertainty, contrasts the ancient and modern sense of a key word, hands the question back.",
  lament:
    "Deliberately does NOT resolve. Names a real loss in the passage plainly, stays inside the text's grief without explaining it away, ends with the sufferer still speaking to God. Do not mark it down for lacking comfort or a lesson. DO mark it down if the passage contains no real grief, loss or protest and the devotional has to import one.",
  question:
    "Opens on one real, possibly uncomfortable question, states the strongest objection fairly, separates what the text states from what it implies, ends with the question sharpened.",
  character:
    "Follows one biblical person across an arc (not a single scene), shows change over time and what God did with their failure, and keeps them a person rather than a moral type.",
};

export interface JudgeVerse {
  book: string;
  chapter: number;
  verse: number;
  text: string;
}

export interface JudgeInput {
  message: string;
  track: string;
  verses: JudgeVerse[];
  holidayName?: string | null;
}

export interface JudgeResult {
  version: string;
  scores: Record<JudgeCriterion, number>;
  overall: number;
  threshold: number;
  hard_fails: JudgeHardFail[];
  passed: boolean;
  // Short, specific notes from the judge. Stored for review; never shown.
  reasons: string[];
}

export function buildJudgePrompt(input: JudgeInput): string {
  const verseLines = input.verses
    .map((v) => `${v.book} ${v.chapter}:${v.verse} — "${v.text}"`)
    .join("\n");
  const intent = TRACK_INTENT[input.track] ??
    "A daily devotional: faithful to the text, specific, and ending in prayer.";
  const holiday = input.holidayName
    ? `\nHOLIDAY\nWritten for ${input.holidayName}; the holiday framing is expected.\n`
    : "";

  return `You are the editor deciding whether today's devotional is good enough to publish in SwiftBible, a Bible app read daily by a wide range of people. Grade it strictly against the rubric. You are not the author; do not be generous.

ANCHOR VERSE(S) — KJV, exact text
${verseLines}

TRACK: ${input.track}
What this track is for: ${intent}
${holiday}
The house theology the author was given:
${PROMPT_THEOLOGY_GUARDRAILS}

RUBRIC — score each criterion 1 to 5 using these anchors.

verse_weight — can this passage carry a devotional, and does the piece draw out what is actually there?
  5: rich passage, and the devotional's main point plainly comes from its words.
  3: the passage is thin, or the devotional leans on neighbouring verses for most of its point.
  1: a census line, genealogy, list of names, measurement or itinerary stretched over a theme it does not contain; the devotional mostly talks about something the verse does not say.

faithfulness — accuracy to scripture and to the guardrails above.
  5: every quotation and claim about the text, its context and its people is correct; no invented scenes or motives.
  3: a loose paraphrase or an unhedged speculative claim.
  1: misquotes scripture, gets a fact about the text wrong, or contradicts the guardrails.

substance — does the reader come away with something specific and true?
  5: a concrete insight a thoughtful reader would not have had on their own.
  3: correct but generic; could be written about many verses.
  1: vague, padded, or so short it says almost nothing.

track_fit — does it do what its track is for (see above), on the track's own terms?
  5: clearly that track, done well.  3: recognisable but half-done.  1: wrong mode entirely.

craft — prose and format.
  5: clean, varied, human; follows the markdown skeleton (title line, bolded subtitle, verse blockquote, sections, italic prayer ending in Amen).
  3: noticeable AI tells (em dashes in prose, "not X but Y" pivots, stacked threes, throat-clearing) or a thin section.
  1: broken structure, missing the prayer, or reads as machine output.

HARD FAILS — list any that apply, otherwise an empty list:
  misquoted_scripture, factual_error, theological_error, verse_cannot_carry_devotional, broken_format, inappropriate_content
Only flag one when you can point to the exact sentence.

DEVOTIONAL TO GRADE
<<<
${input.message}
>>>

Return ONLY a JSON object, no commentary:
{
  "scores": { "verse_weight": 1-5, "faithfulness": 1-5, "substance": 1-5, "track_fit": 1-5, "craft": 1-5 },
  "hard_fails": [],
  "reasons": ["one short, specific sentence per weakness, quoting the devotional where useful"]
}`;
}

function clampScore(raw: unknown): number | null {
  const n = typeof raw === "string" ? Number(raw) : raw;
  if (typeof n !== "number" || !Number.isFinite(n)) return null;
  return Math.min(5, Math.max(1, Math.round(n)));
}

export function overallScore(scores: Record<JudgeCriterion, number>): number {
  let weighted = 0;
  let total = 0;
  for (const c of JUDGE_CRITERIA) {
    weighted += scores[c] * JUDGE_WEIGHTS[c];
    total += JUDGE_WEIGHTS[c];
  }
  // 1–5 mean → 0–10, so 1 maps to 0 and 5 to 10.
  const mean = weighted / total;
  return Math.round(((mean - 1) / 4) * 100) / 10;
}

// Turns the judge model's JSON into a decision. Throws on anything it cannot
// score — the caller treats a throw as "judge unavailable", not as a fail.
export function parseJudgeResponse(
  content: string,
  threshold = JUDGE_PASS_THRESHOLD,
): JudgeResult {
  let parsed: unknown;
  try {
    parsed = JSON.parse(content);
  } catch {
    // Tolerate a fenced or prefixed object.
    const m = content.match(/\{[\s\S]*\}/);
    if (!m) throw new Error(`judge returned no JSON: ${content.slice(0, 200)}`);
    parsed = JSON.parse(m[0]);
  }
  const obj = parsed as {
    scores?: Record<string, unknown>;
    hard_fails?: unknown;
    reasons?: unknown;
  };
  if (!obj || typeof obj !== "object" || !obj.scores) {
    throw new Error(`judge response missing scores: ${content.slice(0, 200)}`);
  }

  const scores = {} as Record<JudgeCriterion, number>;
  for (const c of JUDGE_CRITERIA) {
    const s = clampScore(obj.scores[c]);
    if (s === null) throw new Error(`judge response missing score for ${c}`);
    scores[c] = s;
  }

  const hard_fails = Array.isArray(obj.hard_fails)
    ? [...new Set(
      obj.hard_fails.filter((h): h is JudgeHardFail =>
        (JUDGE_HARD_FAILS as readonly string[]).includes(h as string)
      ),
    )]
    : [];
  const reasons = Array.isArray(obj.reasons)
    ? obj.reasons.filter((r): r is string => typeof r === "string").slice(0, 10)
    : [];

  const overall = overallScore(scores);
  const belowFloor = JUDGE_CRITERIA.some((c) => scores[c] <= JUDGE_CRITERION_FLOOR);
  const passed = overall >= threshold && hard_fails.length === 0 && !belowFloor;

  return {
    version: JUDGE_PROMPT_VERSION,
    scores,
    overall,
    threshold,
    hard_fails,
    passed,
    reasons,
  };
}

// One OpenAI call. Returns the raw response body too, so the caller can cost
// it with the same extractUsage() it uses for generation.
export async function callJudgeModel(opts: {
  apiKey: string;
  model: string;
  prompt: string;
  fetchFn?: typeof fetch;
  url?: string;
  signal?: AbortSignal;
}): Promise<{ content: string; data: unknown }> {
  const doFetch = opts.fetchFn ?? fetch;
  const response = await doFetch(
    opts.url ?? "https://api.openai.com/v1/chat/completions",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${opts.apiKey}`,
      },
      body: JSON.stringify({
        model: opts.model,
        messages: [
          {
            role: "system",
            content:
              "You are a strict editor of Christian devotionals. Return only valid JSON.",
          },
          { role: "user", content: opts.prompt },
        ],
        response_format: { type: "json_object" },
        max_completion_tokens: 1500,
      }),
      signal: AbortSignal.any([AbortSignal.timeout(60000), ...(opts.signal ? [opts.signal] : [])]),
    },
  );
  if (!response.ok) {
    throw new Error(`judge call failed (${response.status}): ${await response.text()}`);
  }
  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || content.trim().length === 0) {
    throw new Error(`judge returned empty content: ${JSON.stringify(data).slice(0, 300)}`);
  }
  return { content, data };
}

// ─── Retry loop ─────────────────────────────────────────────────────

export interface JudgedAttempt<C, G> {
  attempt: number; // 1-based
  candidate: C;
  generation: G;
  // null when the judge itself failed (network, bad JSON). Fail open: an
  // outage of the grader must not stop the day's devotional.
  judge: JudgeResult | null;
  judgeError?: string;
}

export interface JudgedOutcome<C, G> {
  accepted: JudgedAttempt<C, G> | null;
  // Every attempt that will NOT be published. Record these; never show them.
  rejected: JudgedAttempt<C, G>[];
  // True when every attempt failed and `accepted` is the best of the failures.
  exhausted: boolean;
  retryError?: string;
}

// Generates, judges, and on failure moves to a fresh candidate (a different
// verse on the same track) until one passes or attempts run out. Generic over
// the candidate and generation shapes so the test can drive it with stubs.
//
// On exhaustion or a retry error, use the best completed draft only if it has
// no hard failures and no criterion below the floor. A low overall score may
// be tolerable; known errors are not. With no usable draft return null so the
// handler preserves any existing row. Audit failed judgments immediately,
// including a draft subsequently used as a soft-score fallback.
export async function generateWithJudge<C, G>(opts: {
  first: C;
  next: (tried: C[]) => Promise<C>;
  generate: (candidate: C) => Promise<G>;
  judge: (candidate: C, generation: G) => Promise<JudgeResult>;
  maxAttempts?: number;
  signal?: AbortSignal;
  onFailedAttempt?: (attempt: JudgedAttempt<C, G>) => Promise<void>;
  log?: (msg: string) => void;
}): Promise<JudgedOutcome<C, G>> {
  const max = Math.max(1, opts.maxAttempts ?? JUDGE_MAX_ATTEMPTS);
  const log = opts.log ?? console.log;
  const attempts: JudgedAttempt<C, G>[] = [];
  const tried: C[] = [];
  let candidate = opts.first;
  let retryError: string | undefined;

  for (let n = 1; n <= max; n++) {
    let generation: G;
    try {
      opts.signal?.throwIfAborted();
      if (n > 1) candidate = await opts.next(tried);
      tried.push(candidate);
      generation = await opts.generate(candidate);
    } catch (err) {
      if (attempts.length === 0) throw err;
      retryError = err instanceof Error ? err.message : String(err);
      log(`judge attempt ${n}: retry stopped (${retryError})`);
      break;
    }
    let judge: JudgeResult | null = null;
    let judgeError: string | undefined;
    try {
      judge = await opts.judge(candidate, generation);
    } catch (err) {
      judgeError = err instanceof Error ? err.message : String(err);
      log(`judge attempt ${n}: judge unavailable, accepting unjudged (${judgeError})`);
    }

    const attempt: JudgedAttempt<C, G> = { attempt: n, candidate, generation, judge, judgeError };
    attempts.push(attempt);

    if (judge === null || judge.passed) {
      if (judge) log(`judge attempt ${n}: PASS ${judge.overall}/${judge.threshold}`);
      return { accepted: attempt, rejected: attempts.slice(0, -1), exhausted: false };
    }
    log(
      `judge attempt ${n}: FAIL ${judge.overall}/${judge.threshold}` +
        (judge.hard_fails.length ? ` hard_fails=${judge.hard_fails.join(",")}` : ""),
    );
    // Persist before starting another slow external request. Audit errors do
    // not discard the completed draft or stop the remaining quality checks.
    try {
      await opts.onFailedAttempt?.(attempt);
    } catch (err) {
      log(`judge attempt ${n}: audit failed (${String(err)})`);
    }
  }

  const usable = attempts.filter((a) => a.judge && a.judge.hard_fails.length === 0 &&
    JUDGE_CRITERIA.every((c) => a.judge!.scores[c] > JUDGE_CRITERION_FLOOR));
  const best = usable.reduce<JudgedAttempt<C, G> | null>(
    (a, b) => !a || b.judge!.overall > a.judge!.overall ? b : a, null,
  );
  log(best ? `judge: using soft-score fallback (attempt ${best.attempt}, ${best.judge!.overall})` : "judge: no usable draft; preserving existing content");
  return { accepted: best, rejected: attempts.filter((a) => a !== best), exhausted: true, retryError };
}
