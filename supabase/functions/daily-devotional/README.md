# Daily Devotional Edge Function

Generates AI-powered daily devotionals with verse-accurate KJV text. Runs as a Supabase Edge Function triggered daily.

## Devotional Types

There are two devotional types that rotate on a 3-day cycle:

| Day | Type | Testament | Description |
|-----|------|-----------|-------------|
| 1 | Single | Old | One OT verse, full devotional |
| 2 | Single | New | One NT verse, full devotional |
| 3 | Multi | Random | 2 thematically connected verses |
| 4 | Single | Old | Cycle repeats... |

**Holidays override the cycle** and always produce a multi-verse devotional themed to the holiday.

---

## Quality gate (judge)

Every draft is graded before it is saved. The flows below show one
generation; in practice the `generateDevotional` → `saveDevotional` step is:

```
generateWithJudge()                         [_shared/devotional-judge.ts]
  ├── generateDevotional(prompt)            [DEVOTIONAL_MODEL]
  ├── judgeDraft()                          [JUDGE_MODEL, JSON mode]
  │     └── scores 1–5: verse_weight, faithfulness, substance, track_fit, craft
  │         + hard fails (misquoted_scripture, factual_error, theological_error,
  │           verse_cannot_carry_devotional, broken_format, inappropriate_content)
  ├── PASS → publish
  └── FAIL → buildCandidate(): same track, type and testament, different verse
             (holidays: next unused curated verse, then the testament pool)
             … up to JUDGE_MAX_ATTEMPTS (3) drafts

recordRejections()   → daily_devotional_rejections (one row per failed draft)
saveDevotional()     → "Daily Devotional", with the judge result in `judge`
```

- **Pass rule** (decided in code, never by a verdict the model writes):
  weighted overall ≥ `JUDGE_PASS_THRESHOLD` (7.0 / 10), no criterion at or
  below 2, no hard fails.
- **Failed drafts are never published.** They live only in
  `daily_devotional_rejections` (RLS on, service role only), with the draft,
  prompt, verses, cost and the judge's scores and reasons.
- **All attempts fail:** the highest-scoring draft is published so the day is
  not empty, its `judge.exhausted` is `true`, and a Sentry error is raised.
- **Judge unavailable** (network, bad JSON): fail open. The draft is
  published with `judge.result = null` and `judge.error` set.

Useful queries:

```sql
-- what got thrown away, and why
select for_date, attempt, track, verses, judge_score, judge->'hard_fails', judge->'reasons'
from daily_devotional_rejections order by created_at desc;

-- published rows that only got through on exhaustion or unjudged
select for_date, judge from "Daily Devotional"
where (judge->>'exhausted')::boolean or judge->'result' = 'null'::jsonb;
```

### Evals

- `judge_test.ts` (always runs in CI): parser, pass rule, retry loop with
  stubbed model calls, index.ts wiring, and checks on the eval fixtures.
- `judge_eval_test.ts` (opt-in, live model): runs the real judge over the
  labelled cases in `evals/judge_cases.ts` and fails on any disagreement.

  ```bash
  OPENAI_API_KEY=sk-... make eval-devotional-judge           # one pass
  OPENAI_API_KEY=sk-... TRIALS=3 make eval-devotional-judge  # stability
  ```

  Run it after changing the rubric, weights, threshold or `JUDGE_MODEL`, and
  bump `JUDGE_PROMPT_VERSION` when the rubric changes. When the judge gets a
  real day wrong, add that day to `evals/judge_cases.ts` with the right label.

---

## Flow: Single Verse (Old Testament)

```
determineDevotionalType()
  ├── checks yesterday's DB entry
  └── yesterday was "multi" → today is "single", testament: "old"

selectRandomVerse("old")
  ├── picks random book from OT_BOOKS (Genesis–Malachi)
  ├── picks random chapter → random paragraph
  ├── filters: skip if > 400 chars (genealogies) or < 20 chars
  ├── retries up to 10 times
  └── fallback: Psalms (always devotional-worthy)

createPrompt(verse, date, null)
  └── single-verse prompt template with verse text

generateDevotional(prompt)  [gpt-5.4]
  └── returns markdown devotional

saveDevotional(message, date, "old", "single", [verse])
  └── upserts to "Daily Devotional" table
```

## Flow: Single Verse (New Testament)

```
determineDevotionalType()
  ├── checks yesterday's DB entry
  └── yesterday was "single" + "old" → today is "single", testament: "new"

selectRandomVerse("new")
  ├── picks random book from NT_BOOKS (Matthew–Revelation)
  ├── same filtering as OT (skip long/short paragraphs)
  └── fallback: John

createPrompt(verse, date, null)
  └── single-verse prompt template

generateDevotional(prompt)  [gpt-5.4]

saveDevotional(message, date, "new", "single", [verse])
```

## Flow: Multi-Verse (Non-Holiday)

```
determineDevotionalType()
  ├── checks yesterday's DB entry
  └── yesterday was "single" + "new" → today is "multi"

verseCount = random(2 or 3)

selectMultiVerses(verseCount, null)  [gpt-5-mini]
  ├── prompt: "pick N thematically connected KJV verses"
  ├── response_format: json_object
  ├── returns: [{ book, chapter, verse }, ...]
  └── fast + cheap (~300 tokens max)

for each verse ref:
  lookupVerseText(book, chapter, verse)  [bible.json]
    ├── finds exact paragraph text
    ├── strips <JESUS> tags
    └── fallback: "[Book Chapter:Verse]" if not found

  determine testament:
    └── OT_BOOKS.includes(book) ? "old" : "new"

createMultiVersePrompt(resolvedVerses, date, null)
  ├── lists all verses with exact KJV text
  └── non-holiday template (thematic thread, cross-references)

generateDevotional(prompt)  [gpt-5.4]
  └── weaves all verified verses into one devotional

saveDevotional(message, date, testament, "multi", verses)
```

## Flow: Holiday (Always Multi-Verse)

```
getHoliday(today)
  ├── checks Easter-based holidays (offset from computeEaster)
  │   └── Shrove Tue, Ash Wed, Laetare Sun, Palm Sun,
  │       Holy Mon, Spy Wed, Maundy Thu, Good Fri,
  │       Holy Sat, Easter, Ascension, Pentecost, Trinity Sun
  │
  ├── checks fixed-date holidays (month-day lookup)
  │   └── New Year's, Epiphany Eve, Epiphany, Valentine's,
  │       St. Patrick's, Spring Equinox, Earth Day, Flag Day,
  │       Juneteenth, Summer Solstice, Independence Day,
  │       Transfiguration, Patriot Day, Int'l Day of Peace,
  │       Autumn Equinox, Michaelmas, Reformation Day,
  │       All Saints', Veterans Day, Winter Solstice,
  │       Christmas Eve, Christmas, New Year's Eve
  │
  └── checks moveable holidays (computed per year)
      └── MLK Day, Presidents' Day, Memorial Day, Mother's Day,
          Father's Day, Labor Day, Baptism of Jesus,
          World Day of Prayer, National Day of Prayer,
          Election Day, Thanksgiving, Christ the King Sun,
          4 Advent Sundays

determineDevotionalType(supabase, today, holiday)
  └── holiday detected → always returns { type: "multi" }

verseCount = random(2 or 3)

selectMultiVerses(verseCount, holiday)  [gpt-5-mini]
  ├── prompt includes: holiday.themeHint
  ├── "pick N verses related to [Holiday Name]"
  └── verse selection is themed but different each year

for each verse ref:
  lookupVerseText(book, chapter, verse)  [bible.json]
    └── exact KJV text, <JESUS> tags stripped

createMultiVersePrompt(resolvedVerses, date, holiday)
  ├── lists all verses with exact KJV text
  ├── includes holiday.themeHint
  ├── title includes holiday name
  └── modern relevance connects to holiday significance

generateDevotional(prompt)  [gpt-5.4]

saveDevotional(message, date, testament, "multi", verses)
```

## Flow: Single Verse on a Holiday

This happens when the rotation says "single" but it's a holiday. The holiday's curated verse pool is used instead of a random Bible verse.

```
getHoliday(today) → holiday detected

determineDevotionalType()
  └── holiday → always "multi" (overrides rotation)
```

So single-verse mode **never fires on holidays**. The rotation picks back up on the next non-holiday day based on yesterday's `devotional_type`.

---

## Models

| Model | Purpose | Max Tokens |
|-------|---------|------------|
| `gpt-5.4-mini` | Verse selection (multi-verse step 1) | 300 |
| `gpt-5.4` | Devotional writing (all modes) | 4000 |

## Database Schema

```sql
"Daily Devotional" (
  id              bigint PRIMARY KEY,
  created_at      timestamptz DEFAULT now(),
  message         text DEFAULT '',        -- markdown devotional
  for_date        date UNIQUE NOT NULL,   -- one per day
  testament       text,                   -- 'old' or 'new'
  devotional_type text DEFAULT 'single',  -- 'single' or 'multi'
  verses          jsonb                   -- [{book, chapter, verse, testament}]
)
```

## Verse Accuracy

All verse text comes from `bible.json` (bundled KJV data) via `lookupVerseText()`:
- Strips `<JESUS>...</JESUS>` red-letter tags
- ~89% of holiday verse references resolve directly (matching `startingVerse`)
- ~11% are mid-paragraph; fallback to hardcoded text in holiday definitions

## Testing

```bash
cd supabase/functions/daily-devotional
deno test holidays_test.ts --allow-read
```

18 tests covering: Easter computation, date helpers, holiday dates for 2026-2030, verse validity against bible.json, testament labels, collision detection, and model verification.

## Local Invocation

```bash
make test_daily_devotional

# or manually:
curl -X POST 'http://127.0.0.1:54321/functions/v1/daily-devotional' \
  -H 'Authorization: Bearer $SWIFTBIBLE_KEY' \
  -H 'SuperSecret: $SWIFTBIBLE_SUPERSECRET_KEY'
```
