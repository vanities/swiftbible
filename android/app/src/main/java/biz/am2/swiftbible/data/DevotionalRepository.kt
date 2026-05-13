package biz.am2.swiftbible.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.Request
import java.net.URLEncoder
import java.time.LocalDate
import java.util.concurrent.TimeUnit

@Serializable
data class DevotionalVerse(
    val book: String,
    val chapter: Int,
    val verse: Int,
    val testament: String? = null,
)

@Serializable
data class DailyDevotional(
    val id: Long? = null,
    val message: String = "",
    val for_date: String,
    val devotional_type: String? = null,
    val series_name: String? = null,
    val series_part: Int? = null,
    val holiday_name: String? = null,
    val holiday_url: String? = null,
    val anchor_verse: String? = null,
    val verses: List<DevotionalVerse>? = null,
    val model: String? = null,
    val track: String? = null,
)

private val Context.devotionalCache by preferencesDataStore(name = "devotional_cache")

class DevotionalRepository(private val context: Context) {

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    sealed class Result {
        data class Success(val devotional: DailyDevotional) : Result()
        data object NotFound : Result()
        data class Failure(val message: String) : Result()
    }

    suspend fun fetch(date: LocalDate): Result = withContext(Dispatchers.IO) {
        val key = date.toString()
        // Check cache first
        cached(key)?.let { return@withContext Result.Success(it) }

        // PostgREST table path needs %20 (not + which URLEncoder produces)
        val encoded = URLEncoder.encode("Daily Devotional", "UTF-8").replace("+", "%20")
        val url = "${SupabaseConfig.URL}/rest/v1/$encoded?for_date=eq.$key&select=*&limit=1"
        val req = Request.Builder()
            .url(url)
            .header("apikey", SupabaseConfig.ANON_KEY)
            .header("Authorization", "Bearer ${SupabaseConfig.ANON_KEY}")
            .header("Accept", "application/json")
            .build()

        try {
            client.newCall(req).execute().use { response ->
                if (!response.isSuccessful) {
                    return@withContext Result.Failure("HTTP ${response.code}")
                }
                val body = response.body?.string().orEmpty()
                val list = json.decodeFromString<List<DailyDevotional>>(body)
                val devotional = list.firstOrNull() ?: return@withContext Result.NotFound
                cache(key, devotional)
                Result.Success(devotional)
            }
        } catch (t: Throwable) {
            Result.Failure(t.message ?: "Network error")
        }
    }

    private suspend fun cached(dateKey: String): DailyDevotional? {
        val k = stringPreferencesKey("d_$dateKey")
        val str = context.devotionalCache.data.first()[k] ?: return null
        return runCatching { json.decodeFromString<DailyDevotional>(str) }.getOrNull()
    }

    private suspend fun cache(dateKey: String, devotional: DailyDevotional) {
        val k = stringPreferencesKey("d_$dateKey")
        context.devotionalCache.edit { it[k] = json.encodeToString(DailyDevotional.serializer(), devotional) }
    }

    /** Total bytes used by the devotional cache (UTF-8 length sum of all cached entries). */
    suspend fun cacheSizeBytes(): Long = withContext(Dispatchers.IO) {
        runCatching {
            context.devotionalCache.data.first().asMap().values
                .filterIsInstance<String>()
                .sumOf { it.toByteArray(Charsets.UTF_8).size.toLong() }
        }.getOrDefault(0L)
    }

    suspend fun clearAllCache() = withContext(Dispatchers.IO) {
        runCatching { context.devotionalCache.edit { it.clear() } }
    }
}

fun formatBytes(bytes: Long): String = when {
    bytes >= 1_048_576 -> "%.1f MB".format(bytes / 1_048_576.0)
    bytes >= 1_024 -> "%.1f KB".format(bytes / 1_024.0)
    else -> "$bytes B"
}
