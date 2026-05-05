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

class SummariesRepository(private val context: Context) {
    private val json = Json { ignoreUnknownKeys = true }
    private var loaded: SummariesPayload? = null

    suspend fun get(): SummariesPayload = withContext(Dispatchers.IO) {
        loaded?.let { return@withContext it }
        val text = context.assets.open("summaries_swiftbible.json").bufferedReader().use { it.readText() }
        val parsed = json.decodeFromString<SummariesPayload>(text)
        loaded = parsed
        parsed
    }

    suspend fun chapterTitle(book: String, chapter: Int): String? =
        get().chapterTitles[book]?.get(chapter.toString())

    suspend fun passageSummaries(book: String, chapter: Int): List<PassageSummary> =
        get().passageSummaries[book]?.get(chapter.toString()) ?: emptyList()
}
