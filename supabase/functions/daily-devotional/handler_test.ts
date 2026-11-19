// Exercise the real handler, Supabase client and model request construction.
// The fetch boundary is intercepted: no production data or model traffic.
import { handleRequest } from "./index.ts";
import { JUDGE_CRITERIA } from "../_shared/devotional-judge.ts";
import { isLamentCapable, type VerseBook } from "../_shared/verse-selection.ts";
import bibleJson from "./bible.json" with { type: "json" };

function assert(value: unknown, message: string): asserts value {
  if (!value) throw new Error(message);
}
// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

// Selection returns paragraph starts, so a stored verse ref names a paragraph.
function paragraphText(v: Row): string {
  const paragraph = (bibleJson as unknown as VerseBook[])
    .find((b) => b.name === v.book)?.chapters.find((c) => c.number === v.chapter)
    ?.paragraphs.find((p) => p.startingVerse === v.verse);
  assert(paragraph, `${v.book} ${v.chapter}:${v.verse} is not a paragraph start`);
  return paragraph.text;
}
const HARD = "hard" as const;
interface Scenario {
  judgments: Array<number | "hard" | "down">;
  // Yesterday's track; the default (josh) schedules lament for today.
  prevTrack?: string;
  multi?: boolean;
  holiday?: boolean;
  // Companion the selector returns on each call, in order; the default is a
  // grieving companion so multi-verse lament days can pass validation.
  companions?: Array<{ book: string; chapter: number; verse: number }>;
  generationDown?: boolean;
  failGeneration?: number;
  failSelectionAfter?: number;
  repeatedCompanion?: boolean;
  auditError?: boolean;
  cached?: boolean;
  denied?: boolean;
}

Deno.test("real devotional handler recovery and persistence", async (t) => {
  const originalFetch = globalThis.fetch;
  const originalRandom = Math.random;
  const originalLog = console.log;
  const env = {
    SUPABASE_URL: "http://review-database.invalid",
    SUPABASE_SERVICE_ROLE_KEY: "review-key",
    SUPER_SECRET: "review-secret",
    OPENAI_API_KEY: "review-key",
  };
  const previous = Object.fromEntries(
    Object.keys(env).map((key) => [key, Deno.env.get(key)]),
  );
  for (const [key, value] of Object.entries(env)) Deno.env.set(key, value);
  console.log = () => {};

  async function run(scenario: Scenario) {
    let generated = 0, selected = 0, judged = 0;
    const writes: Array<{ table: string; rows: Row | Row[] }> = [];
    const order: string[] = [];
    const signals: AbortSignal[] = [];
    // A constant RNG recreates the original duplicate seed bug reliably.
    Math.random = () => 0.2;
    const json = (value: unknown, status = 200) =>
      new Response(JSON.stringify(value), {
        status,
        headers: { "Content-Type": "application/json" },
      });
    globalThis.fetch = (input, init) => {
      const url = new URL(
        input instanceof Request ? input.url : input.toString(),
      );
      if (url.hostname === "review-database.invalid") {
        if ((init?.method ?? "GET") === "GET") {
          const select = url.searchParams.get("select");
          if (select === "message") {
            return Promise.resolve(
              json(scenario.cached ? { message: "existing devotional" } : null),
            );
          }
          if (select === "track") {
            return Promise.resolve(json({ track: scenario.prevTrack ?? "josh" }));
          }
          if (select === "testament,devotional_type") {
            return Promise.resolve(
              json({
                testament: "new",
                devotional_type: scenario.multi ? "single" : "multi",
              }),
            );
          }
          throw new Error(`Unexpected database read: ${select}`);
        }
        assert(init?.signal, "database writes must have a timeout");
        const table = decodeURIComponent(url.pathname.split("/").at(-1)!);
        order.push(table);
        writes.push({ table, rows: JSON.parse(init!.body as string) });
        return Promise.resolve(
          scenario.auditError && table === "daily_devotional_rejections"
            ? json({ message: "audit unavailable" }, 500)
            : new Response(null, { status: 201 }),
        );
      }
      assert(
        url.hostname === "api.openai.com",
        `Unexpected network request: ${url.hostname}`,
      );
      assert(init?.signal, "every model request must have a time limit");
      signals.push(init.signal);
      const body = JSON.parse(init.body as string);
      const system = body.messages[0].content;
      let content: string;
      if (system.includes("strict editor")) {
        const value = scenario.judgments[judged++];
        order.push("judge");
        if (value === "down") {
          return Promise.resolve(json({ error: "judge down" }, 503));
        }
        assert(value !== undefined, "unexpected judge call");
        content = JSON.stringify({
          scores: Object.fromEntries(
            JUDGE_CRITERIA.map((
              c,
            ) => [c, value === "hard" ? c === "faithfulness" ? 2 : 5 : value]),
          ),
          hard_fails: value === "hard" ? ["misquoted_scripture"] : [],
          reasons: [],
        });
      } else if (system.includes("verse selector")) {
        selected++;
        order.push("selection");
        if (
          scenario.failSelectionAfter !== undefined &&
          selected > scenario.failSelectionAfter
        ) return Promise.resolve(json({ error: "selection down" }, 503));
        const companion = scenario.companions?.[selected - 1] ??
          (scenario.repeatedCompanion || selected === 1
            ? { book: "Matthew", chapter: 26, verse: 38 } // My soul is exceeding sorrowful
            : { book: "Luke", chapter: 19, verse: 41 }); // he beheld the city, and wept over it
        content = JSON.stringify({ verses: [companion] });
      } else {
        generated++;
        order.push(`generate-${generated}`);
        if (scenario.generationDown || generated === scenario.failGeneration) {
          return Promise.resolve(json({ error: "generation down" }, 503));
        }
        content = `# Draft ${generated}`;
      }
      return Promise.resolve(
        json({
          choices: [{ message: { content } }],
          usage: { prompt_tokens: 10, completion_tokens: 20, total_tokens: 30 },
        }),
      );
    };
    const response = await handleRequest(
      new Request("http://review-handler.invalid", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          SuperSecret: scenario.denied ? "wrong" : "review-secret",
        },
        body: JSON.stringify({
          forDate: scenario.holiday ? "2026-12-25" : "2026-10-12",
        }),
      }),
    );
    const published = writes.find((w) => w.table === "Daily Devotional")
      ?.rows as Row | undefined;
    const rejected = writes.filter((w) =>
      w.table === "daily_devotional_rejections"
    ).flatMap((w) => w.rows);
    return {
      status: response.status,
      body: await response.text(),
      published,
      rejected,
      generated,
      selected,
      order,
      signals,
    };
  }
  try {
    await t.step(
      "authorization and cached content make no model calls",
      async () => {
        const denied = await run({ judgments: [], denied: true });
        assert(
          denied.status === 403 && denied.generated === 0,
          "unauthorized request generated content",
        );
        const cached = await run({ judgments: [], cached: true });
        assert(
          cached.body === "existing devotional" && cached.generated === 0,
          "cache should be returned unchanged",
        );
      },
    );
    await t.step(
      "single retry uses a new passage and persists failure before generating again",
      async () => {
        const r = await run({ judgments: [2, 4] });
        assert(
          r.status === 200 && r.published?.judge.result.passed &&
            r.rejected.length === 1,
          "retry did not publish the passing draft",
        );
        assert(
          JSON.stringify(r.published.verses) !==
            JSON.stringify(r.rejected[0].verses),
          "retry reused the rejected verse",
        );
        assert(
          r.order.indexOf("daily_devotional_rejections") <
            r.order.indexOf("generate-2"),
          "audit happened too late",
        );
        assert(
          r.rejected[0].run_id === r.published.judge.run_id,
          "audit and published result must identify the same run",
        );
      },
    );
    for (const stage of ["generation", "selection"]) {
      await t.step(
        `a later ${stage} outage preserves the earlier usable draft and audit`,
        async () => {
          const r = await run({
            judgments: [3],
            ...(stage === "generation"
              ? { failGeneration: 2 }
              : { multi: true, failSelectionAfter: 1 }),
          });
          assert(
            r.status === 200 && r.published?.judge.exhausted &&
              r.rejected.length === 1,
            "fallback or audit lost",
          );
          assert(
            r.published.judge.retry_error.includes(`${stage}`),
            "retry error missing from row",
          );
        },
      );
    }
    await t.step(
      "known errors cannot win fallback ranking or overwrite existing content",
      async () => {
        const r = await run({ judgments: [3, "hard", 3] });
        assert(
          r.status === 200 && r.published?.judge.attempt === 1 &&
            r.rejected.length === 3,
          "hard failure selected or audit missing",
        );
        // Every draft on the scheduled track and on its rescue track is unsafe.
        const blocked = await run({ judgments: Array(6).fill(HARD) });
        assert(blocked.status === 503 && !blocked.published, "unsafe draft published");
        assert(
          blocked.rejected.length === 6,
          `expected both tracks' 6 drafts audited, got ${blocked.rejected.length}`,
        );
        assert(
          blocked.rejected.map((x) => x.attempt).join(",") === "1,2,3,4,5,6",
          `audit attempts must be unique per run: ${blocked.rejected.map((x) => x.attempt)}`,
        );
        assert(
          blocked.rejected.map((x) => x.track).join(",") ===
            "lament,lament,lament,question,question,question",
          `audit rows must record the track that wrote them: ${blocked.rejected.map((x) => x.track)}`,
        );
      },
    );
    await t.step(
      "a track with no usable draft hands the day to the next track",
      async () => {
        // The 2026-11-11 shape: three lament drafts, each with a floor-level
        // criterion, used to leave the day blank and stall the rotation.
        const r = await run({ judgments: [HARD, HARD, HARD, 4] });
        assert(r.status === 200 && r.published, `day left blank (status ${r.status})`);
        assert(
          r.published.track === "question" &&
            r.published.prompt_version === "question-v1",
          `published ${r.published.track}/${r.published.prompt_version}, expected question/question-v1`,
        );
        assert(r.published.judge.fallback_from === "lament", "row must say which track it replaced");
        assert(
          r.published.judge.attempt === 4 && r.published.judge.attempts === 4,
          `attempt ${r.published.judge.attempt}/${r.published.judge.attempts}, expected 4/4`,
        );
        assert(
          r.rejected.length === 3 &&
            r.rejected.every((x) => x.track === "lament" && x.run_id === r.published!.judge.run_id),
          "the failed lament drafts must stay audited under the same run",
        );
        const tried = new Set(
          r.rejected.flatMap((x) => x.verses.map((v: Row) => `${v.book} ${v.chapter}:${v.verse}`)),
        );
        assert(
          r.published.verses.every((v: Row) => !tried.has(`${v.book} ${v.chapter}:${v.verse}`)),
          "the rescue track redrafted a verse already rejected today",
        );
        const passedFirst = await run({ judgments: [4] });
        assert(
          passedFirst.published?.track === "lament" && !("fallback_from" in passedFirst.published.judge),
          "a passing scheduled track must not be marked as a fallback",
        );
      },
    );
    await t.step(
      "the rescue track is never lament",
      async () => {
        // Yesterday matt, so today is josh and the next track in the cycle
        // would be lament: the rescue skips to question.
        const r = await run({ judgments: [HARD, HARD, HARD, 4], prevTrack: "matt" });
        assert(
          r.published?.track === "question" && r.published.judge.fallback_from === "josh",
          `rescued by ${r.published?.track} from ${r.published?.judge.fallback_from}, expected question from josh`,
        );
      },
    );
    await t.step(
      "a rescue that cannot run keeps the 503 instead of a 500",
      async () => {
        const r = await run({ judgments: [HARD, HARD, HARD], failGeneration: 4 });
        assert(
          r.status === 503 && !r.published && r.rejected.length === 3,
          `status ${r.status}, published ${!!r.published}, rejected ${r.rejected.length}`,
        );
      },
    );
    await t.step(
      "lament anchors voice grief, loss or protest",
      async () => {
        const single = await run({ judgments: [2, 4] });
        assert(single.published?.track === "lament", "expected a lament day");
        assert(single.published.prompt_version === "lament-v2", `prompt ${single.published.prompt_version}`);
        for (const v of [...single.published.verses, ...single.rejected.flatMap((x) => x.verses)]) {
          assert(isLamentCapable(paragraphText(v)), `${v.book} ${v.chapter}:${v.verse} carries no grief`);
        }
        const multi = await run({ judgments: [4], multi: true });
        assert(multi.published?.track === "lament", "expected a multi-verse lament day");
        assert(
          multi.published.verses.every((v: Row) => isLamentCapable(paragraphText(v))),
          "multi-verse lament seed or companion carries no grief",
        );
        assert(
          multi.published.verse_selection_prompt.includes("This devotional is a lament."),
          "companion selection was not told the devotional is a lament",
        );
      },
    );
    await t.step(
      "a lament companion with no grief is reselected before drafting",
      async () => {
        const r = await run({
          judgments: [4],
          multi: true,
          companions: [
            { book: "Matthew", chapter: 6, verse: 33 }, // seek ye first the kingdom
            { book: "Matthew", chapter: 26, verse: 38 },
          ],
        });
        assert(r.selected === 2 && r.generated === 1, `selected ${r.selected}, generated ${r.generated}`);
        assert(
          r.published?.track === "lament" &&
            `${r.published.verses[1].book} ${r.published.verses[1].chapter}:${r.published.verses[1].verse}` ===
              "Matthew 26:38",
          "the grieving companion should replace the rejected one",
        );
      },
    );
    await t.step(
      "a scheduled track that fails before any draft is rescued",
      async () => {
        // The first generation errors (the shape of the unexplained 2026-11-01
        // and 2026-09-12 blanks); the rescue track drafts and publishes.
        const r = await run({ judgments: [4], failGeneration: 1 });
        assert(r.status === 200 && r.published, `status ${r.status}`);
        assert(
          r.published.track === "question" && r.published.judge.fallback_from === "lament",
          `published ${r.published.track} from ${r.published.judge.fallback_from}`,
        );
        assert(
          r.published.judge.attempt === 1 && r.rejected.length === 0,
          "no draft was judged before the rescue, so it is attempt 1",
        );
        const down = await run({ judgments: [], generationDown: true });
        assert(
          down.status === 500 && !down.published && down.rejected.length === 0,
          `a total outage must stay a 500 with nothing written (status ${down.status})`,
        );
      },
    );
    await t.step(
      "multi retries exclude both prior seed and companion",
      async () => {
        const r = await run({ judgments: [2, 4], multi: true });
        assert(
          r.status === 200 && r.published && r.rejected.length === 1,
          "multi retry failed",
        );
        const previous = new Set(
          r.rejected[0].verses.map((v: Row) =>
            `${v.book} ${v.chapter}:${v.verse}`
          ),
        );
        assert(
          r.published.verses.every((v: Row) =>
            !previous.has(`${v.book} ${v.chapter}:${v.verse}`)
          ),
          "multi retry reused a reference",
        );
        const repeat = await run({
          judgments: [3],
          multi: true,
          repeatedCompanion: true,
        });
        assert(
          repeat.generated === 1 && repeat.published?.judge.retry_error,
          "repeated companion reached generation",
        );
      },
    );
    await t.step(
      "holiday retry advances to an unused curated verse",
      async () => {
        const r = await run({ judgments: [2, 4], holiday: true });
        assert(
          r.status === 200 && r.published &&
            r.published.holiday_name?.startsWith("Christmas"),
          "holiday metadata lost",
        );
        // Yesterday josh schedules lament; holidays skip it before any draft.
        assert(
          r.published.track === "question" &&
            r.rejected.every((x) => x.track === "question") &&
            !("fallback_from" in r.published.judge),
          `holiday ran ${r.published.track} (rejections: ${r.rejected.map((x) => x.track)})`,
        );
        assert(
          JSON.stringify(r.published.verses) !==
            JSON.stringify(r.rejected[0].verses),
          "holiday verse reused",
        );
      },
    );
    await t.step(
      "judge and audit outages preserve documented availability behavior",
      async () => {
        const r = await run({ judgments: ["down"] });
        assert(
          r.status === 200 && r.published?.judge.result === null &&
            r.published.judge.error,
          "judge outage metadata missing",
        );
        const audit = await run({ judgments: [2, 4], auditError: true });
        assert(
          audit.status === 200 && audit.published?.judge.result.passed,
          "audit failure blocked passing draft",
        );
      },
    );
  } finally {
    globalThis.fetch = originalFetch;
    Math.random = originalRandom;
    console.log = originalLog;
    for (const [key, value] of Object.entries(previous)) {
      value === undefined ? Deno.env.delete(key) : Deno.env.set(key, value);
    }
  }
});
