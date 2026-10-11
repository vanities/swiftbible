// Exercise the real handler, Supabase client and model request construction.
// The fetch boundary is intercepted: no production data or model traffic.
import { handleRequest } from "./index.ts";
import { JUDGE_CRITERIA } from "../_shared/devotional-judge.ts";

function assert(value: unknown, message: string): asserts value {
  if (!value) throw new Error(message);
}
// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;
interface Scenario {
  judgments: Array<number | "hard" | "down">;
  multi?: boolean;
  holiday?: boolean;
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
            return Promise.resolve(json({ track: "josh" }));
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
        const companion = scenario.repeatedCompanion || selected === 1
          ? { book: "Matthew", chapter: 6, verse: 33 }
          : { book: "John", chapter: 3, verse: 16 };
        content = JSON.stringify({ verses: [companion] });
      } else {
        generated++;
        order.push(`generate-${generated}`);
        if (generated === scenario.failGeneration) {
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
        const blocked = await run({ judgments: ["hard", "hard", "hard"] });
        assert(
          blocked.status === 503 && !blocked.published &&
            blocked.rejected.length === 3,
          "unsafe draft published",
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
