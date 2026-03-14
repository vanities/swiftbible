-- Add testament column to track OT/NT alternation for daily devotionals
ALTER TABLE public."Daily Devotional"
  ADD COLUMN IF NOT EXISTS testament text;
