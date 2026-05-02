-- Backfill `cost_usd` into the `usage` JSONB for rows generated before
-- the cost-tracking change. Pricing matches MODEL_PRICING in the Edge
-- Function (USD per million tokens), snapshotted 2026-05-02:
--
--   gpt-5.5:        input $5.00  / output $30.00
--   gpt-5.4:        input $2.50  / output $15.00
--   gpt-5.4-mini:   input $0.75  / output  $4.50
--
-- Cost = (prompt_tokens * input_rate + completion_tokens * output_rate)
--      / 1,000,000
--
-- This only touches rows where usage exists but cost_usd is missing.

CREATE OR REPLACE FUNCTION pg_temp.compute_call_cost(
  model TEXT,
  prompt_tokens NUMERIC,
  completion_tokens NUMERIC
) RETURNS NUMERIC AS $$
  SELECT ROUND(
    (
      prompt_tokens *
        CASE model
          WHEN 'gpt-5.5'      THEN 5.00
          WHEN 'gpt-5.4'      THEN 2.50
          WHEN 'gpt-5.4-mini' THEN 0.75
          ELSE 0
        END
      + completion_tokens *
        CASE model
          WHEN 'gpt-5.5'      THEN 30.00
          WHEN 'gpt-5.4'      THEN 15.00
          WHEN 'gpt-5.4-mini' THEN  4.50
          ELSE 0
        END
    ) / 1000000.0,
    6
  );
$$ LANGUAGE SQL IMMUTABLE;

UPDATE public."Daily Devotional"
   SET usage = jsonb_set(
     CASE
       WHEN usage ? 'selection'
        AND (usage -> 'selection' ->> 'cost_usd') IS NULL
       THEN jsonb_set(
         usage,
         '{selection,cost_usd}',
         to_jsonb(pg_temp.compute_call_cost(
           usage -> 'selection' ->> 'model',
           (usage -> 'selection' ->> 'prompt_tokens')::numeric,
           (usage -> 'selection' ->> 'completion_tokens')::numeric
         ))
       )
       ELSE usage
     END,
     '{generation,cost_usd}',
     to_jsonb(pg_temp.compute_call_cost(
       usage -> 'generation' ->> 'model',
       (usage -> 'generation' ->> 'prompt_tokens')::numeric,
       (usage -> 'generation' ->> 'completion_tokens')::numeric
     ))
   )
 WHERE usage IS NOT NULL
   AND (usage -> 'generation' ->> 'cost_usd') IS NULL;
