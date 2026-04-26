-- Add theme/origin metadata so the iOS app can show readers WHY this
-- devotional exists (holiday context, custom series, or AI seed verse).
ALTER TABLE public."Daily Devotional"
  ADD COLUMN IF NOT EXISTS series_name TEXT,
  ADD COLUMN IF NOT EXISTS series_part INTEGER,
  ADD COLUMN IF NOT EXISTS holiday_name TEXT,
  ADD COLUMN IF NOT EXISTS holiday_url TEXT,
  ADD COLUMN IF NOT EXISTS anchor_verse TEXT;
