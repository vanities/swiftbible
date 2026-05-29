-- Lock down direct client reads of Daily Devotional.
--
-- Current iOS and Android releases now fetch devotionals through the
-- get-daily-devotional Edge Function, which uses the service-role key and
-- validates app headers plus DEVOTIONAL_READ_SECRET before returning the
-- limited public column set. Direct PostgREST reads by anon/authenticated
-- clients are no longer needed and should be denied at the database layer.

DROP POLICY IF EXISTS "Enable read access for all users"
  ON public."Daily Devotional";

REVOKE SELECT ON TABLE public."Daily Devotional" FROM anon;
REVOKE SELECT ON TABLE public."Daily Devotional" FROM authenticated;

-- Keep privileged server-side access for Edge Functions / automation.
GRANT ALL ON TABLE public."Daily Devotional" TO service_role;
