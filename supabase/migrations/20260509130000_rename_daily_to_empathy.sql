-- Rename historical `daily-vN` prompt versions to `empathy-vN`.
--
-- The original v1 → v4 prompt iterations (originally tagged "daily-vN")
-- were all variants of the empathy-driven track. With the introduction
-- of a parallel "technical-v1" track in the same Edge Function release,
-- the "daily-" prefix becomes ambiguous. Backfilling to the explicit
-- "empathy-" prefix keeps the historical record consistent with the
-- track-prefix naming scheme used going forward.
--
-- Mapping:
--   daily-v1 → empathy-v1   (numbered-guidelines, original — see git history)
--   daily-v2 → empathy-v2   (four-beat refactor)
--   daily-v3 → empathy-v3   (added few-shot example)
--   daily-v4 → empathy-v4   (prayer in blockquote — reverted in v6)
--
-- empathy-v5 is the implicit pre-fix state that never shipped.
-- empathy-v6 is the current production prompt.
UPDATE public."Daily Devotional"
   SET prompt_version = REPLACE(prompt_version, 'daily-', 'empathy-')
 WHERE prompt_version LIKE 'daily-v%';
