-- Track which LLM generated each devotional so the iOS app can
-- accurately attribute the model in its disclosure alerts, and so we
-- can swap models server-side without forcing a client update.
ALTER TABLE public."Daily Devotional"
  ADD COLUMN IF NOT EXISTS model TEXT;

COMMENT ON COLUMN public."Daily Devotional".model IS
  'OpenAI model identifier used to generate the devotional (e.g. gpt-5.4). NULL for hand-authored custom devotionals or rows predating this column.';
