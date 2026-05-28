package biz.am2.swiftbible.data

object SupabaseConfig {
    val URL: String = biz.am2.swiftbible.BuildConfig.SUPABASE_URL
    val ANON_KEY: String = biz.am2.swiftbible.BuildConfig.SUPABASE_KEY
    const val POSTHOG_API_KEY = biz.am2.swiftbible.BuildConfig.POSTHOG_API_KEY
    const val DEVOTIONAL_READ_SECRET = biz.am2.swiftbible.BuildConfig.DEVOTIONAL_READ_SECRET
    const val POSTHOG_HOST = "https://us.i.posthog.com"
}
