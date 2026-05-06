package biz.am2.swiftbible.data

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class PassageSummary(val startVerse: Int, val endVerse: Int? = null, val title: String)

@Serializable
data class SummariesPayload(
    val chapterTitles: Map<String, Map<String, String>> = emptyMap(),
    val passageSummaries: Map<String, Map<String, List<PassageSummary>>> = emptyMap(),
)

/**
 * Loads chapter titles and passage summaries from per-source JSON bundled
 * under `assets/`. When the selected source doesn't cover a particular book
 * (e.g., Matthew Henry has no entries for Apocrypha or pseudepigrapha) the
 * lookup falls back to the SwiftBible Curated source, so the picker never
 * hides content — it only changes the primary voice.
 *
 * Mirrors `SummariesService` on iOS.
 */
class SummariesRepository(private val context: Context) {
    private val json = Json { ignoreUnknownKeys = true }
    private val cache = mutableMapOf<SummarySource, SummariesPayload?>()

    private suspend fun get(source: SummarySource): SummariesPayload? = withContext(Dispatchers.IO) {
        cache[source]?.let { return@withContext it }
        val resource = source.resourceName ?: run {
            cache[source] = null
            return@withContext null
        }
        val parsed = runCatching {
            val text = context.assets.open("$resource.json").bufferedReader().use { it.readText() }
            json.decodeFromString<SummariesPayload>(text)
        }.getOrNull()
        cache[source] = parsed
        parsed
    }

    suspend fun chapterTitle(book: String, chapter: Int, source: SummarySource): String? {
        if (source == SummarySource.OFF) return null
        val key = chapter.toString()
        get(source)?.chapterTitles?.get(book)?.get(key)?.takeIf { it.isNotBlank() }?.let { return it }
        if (source == SummarySource.SWIFT_BIBLE) return null
        return get(SummarySource.SWIFT_BIBLE)
            ?.chapterTitles?.get(book)?.get(key)?.takeIf { it.isNotBlank() }
    }

    suspend fun passageSummaries(book: String, chapter: Int, source: SummarySource): List<PassageSummary> {
        if (source == SummarySource.OFF) return emptyList()
        val key = chapter.toString()
        val primary = get(source)?.passageSummaries?.get(book)?.get(key).orEmpty()
        if (primary.isNotEmpty()) return primary
        if (source == SummarySource.SWIFT_BIBLE) return emptyList()
        return get(SummarySource.SWIFT_BIBLE)?.passageSummaries?.get(book)?.get(key).orEmpty()
    }
}
