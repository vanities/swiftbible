-- Track OpenAI token usage per devotional so we can monitor cost,
-- audit which model variants are spending what, and compute spend
-- across date ranges without external instrumentation.
--
-- Stored as JSONB rather than separate columns because multi-verse
-- devotionals make TWO API calls (verse selection + devotional
-- generation), and we want the usage from each captured separately.
--
-- Shape:
--   {
--     "generation": { "model": "gpt-5.4", "prompt_tokens": 450,
--                     "completion_tokens": 1200, "total_tokens": 1650 },
--     "selection":  { "model": "gpt-5.4-mini", "prompt_tokens": 200,
--                     "completion_tokens": 80,  "total_tokens": 280 }
--   }
--
-- `selection` is omitted for single-verse and holiday devotionals.
-- NULL for hand-authored custom devotionals or rows predating this column.
ALTER TABLE public."Daily Devotional"
  ADD COLUMN IF NOT EXISTS usage JSONB;

COMMENT ON COLUMN public."Daily Devotional".usage IS
  'OpenAI token usage for the devotional generation (and verse selection, for multi). JSONB with {generation: {model, prompt_tokens, completion_tokens, total_tokens}, selection?: {...}}. NULL for custom or pre-column rows.';
