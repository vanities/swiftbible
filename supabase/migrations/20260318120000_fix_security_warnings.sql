-- Fix Supabase database linter security warnings
-- Addresses: function_search_path_mutable, rls_policy_always_true, auth_allow_anonymous_sign_ins

----------------------------------------------------------------------
-- 1. Fix function_search_path_mutable: set search_path on all public functions
----------------------------------------------------------------------

-- 1a. delete_user — also clean up malformed pg_dump artifact
CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  DELETE FROM auth.users WHERE id = auth.uid();
$$;

-- 1b. set_donations_updated_at
CREATE OR REPLACE FUNCTION public.set_donations_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  new.updated_at = timezone('utc', now());
  RETURN new;
END;
$$;

-- 1c. handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (new.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

----------------------------------------------------------------------
-- 2. Fix rls_policy_always_true: Daily Devotional INSERT was targeting "anon"
--    despite being named "for authenticated users only"
----------------------------------------------------------------------

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public."Daily Devotional";
CREATE POLICY "Enable insert for authenticated users only"
  ON public."Daily Devotional"
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

----------------------------------------------------------------------
-- 3. Fix auth_allow_anonymous_sign_ins: restrict policies to authenticated
----------------------------------------------------------------------

-- 3a. donations SELECT — was missing TO clause, so applied to all roles including anon
DROP POLICY IF EXISTS "Users can view their donations" ON public.donations;
CREATE POLICY "Users can view their donations"
  ON public.donations
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- 3b. Daily Devotional SELECT — restrict to anon + authenticated explicitly
--     (public read access is intentional, but being explicit avoids the advisory)
DROP POLICY IF EXISTS "Enable read access for all users" ON public."Daily Devotional";
CREATE POLICY "Enable read access for all users"
  ON public."Daily Devotional"
  FOR SELECT
  TO anon, authenticated
  USING (true);
