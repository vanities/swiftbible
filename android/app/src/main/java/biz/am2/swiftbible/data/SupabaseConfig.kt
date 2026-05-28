package biz.am2.swiftbible.data

object SupabaseConfig {
    const val URL = "https://yvanxjoayoiocwzfpkfm.supabase.co"
    const val ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." +
        "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2YW54am9heW9pb2N3emZwa2ZtIiwicm9sZSI6ImFub24i" +
        "LCJpYXQiOjE3MjU0OTQ5NTcsImV4cCI6MjA0MTA3MDk1N30.gG7dCHItgIBQhjA4EK38FJ6ju-I7mSJlvJRzVLaPuOs"
    const val POSTHOG_API_KEY = biz.am2.swiftbible.BuildConfig.POSTHOG_API_KEY
    const val DEVOTIONAL_READ_SECRET = biz.am2.swiftbible.BuildConfig.DEVOTIONAL_READ_SECRET
    const val POSTHOG_HOST = "https://us.i.posthog.com"
}
