# Daily Devotional Edge Function

Generates a daily KJV devotional, judges it, and stores the selected result.
iOS and Android read public fields through `get-daily-devotional`.

## Request and rotation

The caller supplies `SuperSecret`, matching the `SUPER_SECRET` environment
variable. Optional JSON fields:

- `forDate`: UTC civil date (`YYYY-MM-DD`), default today.
- `force`: regenerate an existing date. The existing row is replaced only
  after a publishable draft is available and saved successfully.

Normal requests return existing content before making model calls. Generation
rotates independently through old-testament single, new-testament single, and
multi-verse; and through empathy, technical, narrative, practical, matt, josh,
lament, question and character tracks. Custom rows do not advance the track.
Holidays use one curated verse and retain holiday metadata through retries.

Model IDs live in `index.ts`: `DEVOTIONAL_MODEL`, `VERSE_SELECTION_MODEL`,
and `JUDGE_MODEL`. Model, prompt, prompt version and token usage are stored
with each draft. Environment variables do not override model constants.

## Selection and quality gate

Random anchors are sampled uniformly from eligible paragraphs, so a book's
chance is proportional to its usable material. `_shared/verse-selection.ts`
filters fragments, very long paragraphs, and narrow patterns for census,
genealogy, itinerary and measurement passages (about 0.7% of the eligible
pool). The rules do not infer importance from proper names.

Multi-verse selection chooses a random seed and asks for a companion from
another book. References must resolve to bundled KJV text. Both seed and
companion exclude previously attempted references. Invalid or repeated model
references are retried before spending another generation call.

Each draft is judged on verse weight, faithfulness, substance, track fit and
craft. Code computes the weighted 0–10 score. A normal pass requires:

- overall score at least 7.0;
- every criterion above 2 on its 1–5 scale;
- no hard-failure flags, such as misquoted scripture or factual errors.

At most three drafts are generated on the same track/type/testament. All
selection, generation and judge calls share a 120-second deadline. Database
and Sentry requests have five-second limits, leaving time to persist results
before Supabase's request timeout.

Every failed judgment is immediately written to `daily_devotional_rejections`,
before another model request. Audit errors are reported without discarding
completed drafts. The table has RLS enabled and no app-role table privileges.
A `run_id` and attempt number connect audit records to published metadata and
distinguish repeated invocations.

Outcomes:

- **Pass:** publish with judge scores and attempt count.
- **Exhaustion, retry error or deadline:** use the highest-scoring completed
  draft with no hard failures and every criterion above 2. Mark
  `judge.exhausted = true`, retain `judge.retry_error` if present, and report to
  Sentry. This soft-score fallback remains audited because its judgment failed
  the overall threshold.
- **No usable draft:** return 503, retain all failed judgments, and leave any
  existing devotional untouched. Known errors are never a fallback.
- **Judge unavailable:** retain the established fail-open behavior: publish
  the completed draft with `judge.result = null` and `judge.error` populated.
  An unavailable judge is distinct from a known failed judgment.
- **First generation fails:** return 500 without changing existing content.

```sql
select for_date, run_id, attempt, track, verses, judge_score,
       judge->'hard_fails', judge->'reasons'
from daily_devotional_rejections order by created_at desc;

select for_date, judge from "Daily Devotional"
where (judge->>'exhausted')::boolean or judge->'result' = 'null'::jsonb;
```

## Tests and evaluations

```sh
deno test --allow-all supabase/functions/
deno check supabase/functions/daily-devotional/index.ts
OPENAI_API_KEY=... make eval-devotional-judge TRIALS=3
```

The normal suite covers scoring, retry recovery, deadlines, real request
handler behavior with intercepted network requests, fresh verse selection,
holiday metadata, audit ordering, and bundled KJV fixture accuracy. It never
calls a live model or database. CI also checks request-handler types.

Live evaluations are opt-in and bill model calls. They include the rejected
2026-10-11 Numbers 26:58 devotional, positive examples, invented scenes,
misreadings, theological errors and broken structure. The empathy writer and
its positive evaluation fixture import the same corrected example from
`_shared/devotional-examples.ts`; the former invented-scene example remains
as a negative control. Re-run evaluations when models, rubric or examples
change. Bump the corresponding prompt version when its prompt changes.

## Deployment

Merge to `master` to deploy through GitHub Actions. The Supabase deployment
workflow calls the migration workflow first and deploys functions only after
it succeeds. Production deployment runs are serialized. Do not deploy
functions or push migrations manually.
