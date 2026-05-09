-- Add `track` as a first-class column so we can filter/group rows by
-- prompt track (empathy / technical / future tracks) without parsing the
-- prompt_version string. Also corrects the prior backfill mistake.
--
-- Mistake: 20260509130000_rename_daily_to_empathy.sql renamed every old
-- "daily-vN" row to "empathy-vN". But the original "daily-v1" prompt was
-- the numbered-guidelines / Hebrew/Greek-heavy / italic-meditation
-- template — that's the TECHNICAL track, not the empathy track. The
-- empathy track started with the v2 four-beat refactor (which only had
-- a few rows and were all overwritten by regeneration before this fix
-- ships, so no surviving rows are mislabelled empathy).
--
-- Result: we rename surviving "empathy-v1" rows back to "technical-v1",
-- and backfill the new `track` column from the prompt_version prefix.

ALTER TABLE public."Daily Devotional"
  ADD COLUMN IF NOT EXISTS track TEXT;

COMMENT ON COLUMN public."Daily Devotional".track IS
  'Prompt track that produced this devotional (e.g. "empathy", "technical"). Independent of devotional_type (single/multi/custom). NULL for hand-authored custom devotionals or rows predating this column.';

-- Fix prior mis-rename: original numbered-guidelines template is technical, not empathy.
UPDATE public."Daily Devotional"
   SET prompt_version = 'technical-v1'
 WHERE prompt_version = 'empathy-v1';

-- Backfill `track` from the prompt_version prefix.
UPDATE public."Daily Devotional"
   SET track = SPLIT_PART(prompt_version, '-', 1)
 WHERE track IS NULL
   AND prompt_version LIKE '%-v%';
