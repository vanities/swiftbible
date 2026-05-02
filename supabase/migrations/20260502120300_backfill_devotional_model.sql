-- Backfill the `model` column for AI-generated devotionals predating
-- 20260502120000_add_devotional_model.sql.
--
-- Every AI-generated devotional before that migration was produced by
-- the hardcoded "gpt-5.4" model (verse selection used gpt-5.4-mini, but
-- the `model` column tracks the GENERATION model). Custom devotionals
-- (hand-authored) stay NULL because they have no model.
--
-- The companion `usage` JSONB column is intentionally NOT backfilled —
-- token counts were never captured before
-- 20260502120100_add_devotional_usage.sql, so there is no faithful
-- historical data to populate. For historical cost analysis,
-- cross-reference OpenAI's billing dashboard (daily exports going back
-- ~12 months) by date rather than fabricating per-row estimates.
UPDATE public."Daily Devotional"
   SET model = 'gpt-5.4'
 WHERE model IS NULL
   AND devotional_type IS DISTINCT FROM 'custom';
