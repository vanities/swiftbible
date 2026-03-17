-- Add device info columns to profiles so we can identify Apple devices.
ALTER TABLE "public"."profiles"
  ADD COLUMN IF NOT EXISTS "device_model" text,
  ADD COLUMN IF NOT EXISTS "device_os" text,
  ADD COLUMN IF NOT EXISTS "device_vendor_id" text,
  ADD COLUMN IF NOT EXISTS "device_name" text,
  ADD COLUMN IF NOT EXISTS "last_seen_at" timestamptz;

-- Allow authenticated users to update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());
