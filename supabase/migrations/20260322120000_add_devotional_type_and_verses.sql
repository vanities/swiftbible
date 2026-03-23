-- Add devotional_type and verses columns for multi-verse devotional support
-- Rotation: old single → new single → multi → old single → ...
ALTER TABLE public."Daily Devotional"
  ADD COLUMN IF NOT EXISTS devotional_type text NOT NULL DEFAULT 'single',
  ADD COLUMN IF NOT EXISTS verses jsonb;
