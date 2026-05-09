-- Capture the prompt actually sent to OpenAI alongside each devotional, so
-- we can iterate on prompt design and audit which rows were generated with
-- which template. Three columns:
--
--   prompt_version          — short identifier for the devotional prompt
--                             template (e.g. "daily-v1", "daily-v2"). Lets
--                             us filter "all rows from template vN" without
--                             diffing strings.
--
--   prompt                  — full rendered prompt sent to the devotional
--                             generation model. Includes verse text, date,
--                             holiday context, and the voice/structure
--                             rules. Useful for iterating on prompt design
--                             and post-hoc forensics when a row's tone
--                             feels off.
--
--   verse_selection_prompt  — full rendered prompt sent to the verse
--                             selection model for multi-verse devotionals.
--                             NULL for single-verse rows.
--
-- All three are NULLable: rows predating this column will have NULL until
-- backfill, and custom (hand-authored) devotionals leave them NULL
-- permanently.
ALTER TABLE public."Daily Devotional"
  ADD COLUMN IF NOT EXISTS prompt_version TEXT,
  ADD COLUMN IF NOT EXISTS prompt TEXT,
  ADD COLUMN IF NOT EXISTS verse_selection_prompt TEXT;

COMMENT ON COLUMN public."Daily Devotional".prompt_version IS
  'Identifier for the devotional prompt template version (e.g. "daily-v1"). NULL for hand-authored custom devotionals or rows predating this column.';

COMMENT ON COLUMN public."Daily Devotional".prompt IS
  'Full rendered prompt sent to the devotional generation model. NULL for hand-authored custom devotionals or rows predating this column.';

COMMENT ON COLUMN public."Daily Devotional".verse_selection_prompt IS
  'Full rendered prompt sent to the verse selection model for multi-verse devotionals. NULL for single-verse, custom, or rows predating this column.';
