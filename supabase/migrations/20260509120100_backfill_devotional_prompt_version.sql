-- Backfill `prompt_version` for AI-generated devotionals predating
-- 20260509120000_add_devotional_prompt_capture.sql.
--
-- Every AI devotional before that migration was produced by a single
-- prompt template (the original createPrompt / createMultiVersePrompt
-- pair), which we label "daily-v1" so future template revisions can be
-- compared against it cleanly. Custom (hand-authored) devotionals stay
-- NULL — they have no template.
--
-- The companion `prompt` and `verse_selection_prompt` text columns are
-- intentionally NOT backfilled. The rendered prompts depend on dynamic
-- inputs (verse text, formatted date, holiday context) and reproducing
-- them from saved row data would be a faithful-but-fabricated guess
-- rather than the actual string sent to OpenAI. We rely on
-- `prompt_version` plus the template in git history for context on
-- pre-backfill rows; future rows capture the rendered prompt verbatim.
UPDATE public."Daily Devotional"
   SET prompt_version = 'daily-v1'
 WHERE prompt_version IS NULL
   AND devotional_type IS DISTINCT FROM 'custom';
