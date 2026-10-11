// Live evals for the devotional judge: runs the REAL judge model over the
// labelled cases in evals/judge_cases.ts and checks it makes the publish
// decision a careful editor would.
//
// Costs money and needs the network, so it is opt-in and skipped in CI:
//
//   RUN_JUDGE_EVALS=1 OPENAI_API_KEY=sk-... \
//     deno test --allow-all supabase/functions/daily-devotional/judge_eval_test.ts
//
// or `make eval-devotional-judge`. Optional:
//   JUDGE_EVAL_TRIALS=3   run each case N times (the judge is not
//                         deterministic; a case must be right on every trial)
//   JUDGE_EVAL_CASE=psalm only run cases whose id contains this
//
// Run it whenever the rubric, weights, threshold or JUDGE_MODEL change, and
// bump JUDGE_PROMPT_VERSION when the rubric does. The deterministic checks on
// the fixtures themselves live in judge_test.ts and always run.

import {
  buildJudgePrompt,
  callJudgeModel,
  type JudgeResult,
  parseJudgeResponse,
} from "../_shared/devotional-judge.ts";
import { type JudgeCase, JUDGE_CASES } from "./evals/judge_cases.ts";

const enabled = Deno.env.get("RUN_JUDGE_EVALS") === "1" &&
  !!Deno.env.get("OPENAI_API_KEY");

// The judge model is set in index.ts beside the other model constants (one
// source of truth). index.ts cannot be imported (top-level Deno.serve), so
// read the literal the same way holidays_test.ts reads the others.
function judgeModelFromSource(): string {
  const source = Deno.readTextFileSync(new URL("./index.ts", import.meta.url));
  const m = source.match(/const JUDGE_MODEL = "([^"]+)";/);
  if (!m) throw new Error('index.ts must declare const JUDGE_MODEL = "...";');
  return m[1];
}

interface Trial {
  result: JudgeResult | null;
  error?: string;
}

async function judgeOnce(c: JudgeCase, model: string, apiKey: string): Promise<Trial> {
  try {
    const { content } = await callJudgeModel({
      apiKey,
      model,
      prompt: buildJudgePrompt({
        message: c.message,
        track: c.track,
        verses: c.verses,
        holidayName: c.holidayName ?? null,
      }),
    });
    return { result: parseJudgeResponse(content) };
  } catch (err) {
    return { result: null, error: err instanceof Error ? err.message : String(err) };
  }
}

function trialProblem(c: JudgeCase, t: Trial): string | null {
  if (!t.result) return `judge error: ${t.error}`;
  const decision = t.result.passed ? "pass" : "fail";
  if (decision !== c.expect) return `expected ${c.expect}, judge said ${decision}`;
  if (c.hardFails && !c.hardFails.some((h) => t.result!.hard_fails.includes(h))) {
    return `failed, but without any of the expected hard fails [${c.hardFails.join(", ")}]`;
  }
  return null;
}

Deno.test({
  name: "devotional judge agrees with labelled cases (live model)",
  ignore: !enabled,
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const apiKey = Deno.env.get("OPENAI_API_KEY")!;
    const model = judgeModelFromSource();
    const trials = Math.max(1, Number(Deno.env.get("JUDGE_EVAL_TRIALS") ?? "1"));
    const filter = Deno.env.get("JUDGE_EVAL_CASE");
    const cases = JUDGE_CASES.filter((c) => !filter || c.id.includes(filter));
    if (cases.length === 0) throw new Error(`no cases match JUDGE_EVAL_CASE=${filter}`);

    const results = await Promise.all(
      cases.map(async (c) => ({
        c,
        trials: await Promise.all(
          Array.from({ length: trials }, () => judgeOnce(c, model, apiKey)),
        ),
      })),
    );

    const failures: string[] = [];
    console.log(`\njudge model: ${model}, ${cases.length} cases x ${trials} trial(s)\n`);
    for (const { c, trials: ts } of results) {
      const problems = ts.map((t) => trialProblem(c, t));
      const ok = problems.every((p) => p === null);
      const scores = ts.map((t) =>
        t.result
          ? `${t.result.overall.toFixed(1)}${t.result.hard_fails.length ? `[${t.result.hard_fails.join(",")}]` : ""}`
          : "ERR"
      ).join(" ");
      console.log(`${ok ? "ok  " : "MISS"} ${c.expect.padEnd(4)} ${scores.padEnd(28)} ${c.id}`);
      if (!ok) {
        const first = ts.find((_t, i) => problems[i] !== null);
        failures.push(
          `${c.id}: ${problems.filter(Boolean).join("; ")}\n    label: ${c.why}\n    judge: ${
            first?.result ? JSON.stringify(first.result.scores) + " " + first.result.reasons.join(" | ") : first?.error
          }`,
        );
      }
    }
    const correct = results.length - failures.length;
    console.log(`\n${correct}/${results.length} cases correct\n`);
    if (failures.length > 0) {
      throw new Error(`judge disagreed with ${failures.length} labelled case(s):\n  ${failures.join("\n  ")}`);
    }
  },
});
