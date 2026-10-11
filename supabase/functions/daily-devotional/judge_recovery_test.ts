import {
  generateWithJudge,
  JUDGE_CRITERIA,
  type JudgeResult,
  parseJudgeResponse,
} from "../_shared/devotional-judge.ts";

function verdict(score: number, hard = false): JudgeResult {
  return parseJudgeResponse(JSON.stringify({
    scores: Object.fromEntries(
      JUDGE_CRITERIA.map((c) => [c, hard && c === "faithfulness" ? 2 : score]),
    ),
    hard_fails: hard ? ["misquoted_scripture"] : [],
    reasons: [],
  }));
}
function assert(value: unknown, message: string): asserts value {
  if (!value) throw new Error(message);
}

for (const stage of ["selection", "generation"]) {
  Deno.test(`a later ${stage} failure retains the earlier usable draft`, async () => {
    const outcome = await generateWithJudge({
      first: 1,
      next: () =>
        stage === "selection"
          ? Promise.reject(new Error("selection failed"))
          : Promise.resolve(2),
      generate: (n) =>
        n === 2
          ? Promise.reject(new Error("generation failed"))
          : Promise.resolve("draft"),
      judge: () => Promise.resolve(verdict(3)),
      log: () => {},
    });
    assert(
      outcome.accepted?.candidate === 1,
      "the completed draft must survive a retry error",
    );
    assert(outcome.exhausted, "fallback should be identified");
  });
}

Deno.test("exhaustion excludes hard failures even when they score higher", async () => {
  const outcome = await generateWithJudge({
    first: 1,
    next: () => Promise.resolve(2),
    generate: () => Promise.resolve("draft"),
    judge: (n) => Promise.resolve(verdict(n === 1 ? 3 : 5, n === 2)),
    maxAttempts: 2,
    log: () => {},
  });
  assert(
    outcome.accepted?.candidate === 1,
    "known misquotes must not win the fallback ranking",
  );
});

Deno.test("when every draft hard-fails nothing is approved for publication", async () => {
  const outcome = await generateWithJudge({
    first: 1,
    next: () => Promise.resolve(2),
    generate: () => Promise.resolve("draft"),
    judge: () => Promise.resolve(verdict(5, true)),
    maxAttempts: 2,
    log: () => {},
  });
  assert(
    outcome.accepted === null,
    "all-hard-failure outcome must preserve the existing devotional",
  );
  assert(
    outcome.rejected.length === 2,
    "both failures remain available for auditing",
  );
});

Deno.test("failed drafts are audited before a retry and survive deadline exhaustion", async () => {
  const controller = new AbortController();
  const events: string[] = [];
  const outcome = await generateWithJudge({
    first: 1,
    next: () => {
      events.push("next");
      return Promise.resolve(2);
    },
    generate: () => Promise.resolve("draft"),
    judge: () => Promise.resolve(verdict(3)),
    onFailedAttempt: () => {
      events.push("audit");
      controller.abort(new Error("shared time budget expired"));
      return Promise.resolve();
    },
    signal: controller.signal,
    log: () => {},
  });
  assert(
    events.join() === "audit",
    "no new model work should start after the shared deadline",
  );
  assert(
    outcome.accepted?.candidate === 1,
    "completed usable draft must survive a deadline",
  );
  assert(
    outcome.retryError?.includes("time budget"),
    "deadline reason must be retained",
  );
});

Deno.test("an audit failure does not discard a draft or block a later passing draft", async () => {
  const outcome = await generateWithJudge({
    first: 1,
    next: () => Promise.resolve(2),
    generate: () => Promise.resolve("draft"),
    judge: (n) => Promise.resolve(verdict(n === 1 ? 3 : 4)),
    onFailedAttempt: () => Promise.reject(new Error("audit down")),
    log: () => {},
  });
  assert(
    outcome.accepted?.candidate === 2,
    "publishing should remain available when the audit store fails",
  );
});

Deno.test("a floor-level criterion cannot be used as a soft-score fallback", async () => {
  const outcome = await generateWithJudge({
    first: 1,
    next: () => Promise.resolve(2),
    generate: () => Promise.resolve("draft"),
    judge: () => Promise.resolve(verdict(2)),
    maxAttempts: 1,
    log: () => {},
  });
  assert(outcome.accepted === null, "floor-level drafts must not be published");
});
