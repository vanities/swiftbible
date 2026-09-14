package biz.am2.swiftbible.data

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/** Attribution metadata for a summaries/introductions source file. */
@Serializable
data class SummariesSourceInfo(
    val name: String,
    val shortName: String,
    val year: Int,
    val license: String,
    val attribution: String,
)

/**
 * The longer-form "About this book" essay shown above the chapter list:
 * authorship, date, historical setting, and the occasion/purpose of the book.
 */
@Serializable
data class BookIntro(
    val title: String,
    val paragraphs: List<String> = emptyList(),
)

/**
 * The typography the intro generator restores from the printed commentaries
 * (python_parser/parse_book_intros.py `format_intro`): a paragraph opening
 * "## " is a section heading, and "**text**" is bold — JFB's small-caps
 * emphasis and both authors' numbered points. Nothing else is markup.
 * Mirrors `IntroMarkup` in SummariesService.swift on iOS.
 */
object IntroMarkup {
    data class Run(val text: String, val bold: Boolean)

    fun heading(paragraph: String): String? =
        if (paragraph.startsWith("## ")) paragraph.removePrefix("## ") else null

    fun runs(paragraph: String): List<Run> {
        val parts = paragraph.split("**").toMutableList()
        // An unpaired "**" is literal text, not the start of a bold run that
        // swallows the rest of the paragraph.
        if (parts.size > 1 && parts.size % 2 == 0) {
            val tail = parts.removeAt(parts.lastIndex)
            parts[parts.lastIndex] = parts.last() + "**" + tail
        }
        return parts.mapIndexedNotNull { index, text ->
            if (text.isEmpty()) null else Run(text, bold = index % 2 == 1)
        }
    }
}

@Serializable
data class BookIntrosPayload(
    val source: SummariesSourceInfo,
    val bookIntros: Map<String, BookIntro> = emptyMap(),
)

/**
 * A resolved introduction together with the attribution of whichever source
 * actually supplied it (which may differ from the user's selection when the
 * chosen source doesn't cover that book and the fallback chain kicks in).
 */
data class ResolvedBookIntro(
    val intro: BookIntro,
    val attribution: SummariesSourceInfo,
)

/**
 * Loads the "About this book" introductions from per-source JSON bundled
 * under `assets/`. When the selected source doesn't cover a particular book
 * the lookup falls back through the other sources — SwiftBible Curated first
 * (the only home of the apocrypha/pseudepigrapha intros), then the two
 * public-domain commentaries — so the entry point is populated whenever any
 * source covers the book.
 *
 * Mirrors the book-introduction half of `SummariesService` on iOS.
 *
 * The resource loader is injected so the parsing and fallback resolution can
 * be unit tested with plain JSON strings; production code uses the [Context]
 * constructor, which reads from `assets/`.
 */
class BookIntroRepository(private val loadResource: (resourceName: String) -> String?) {

    constructor(context: Context) : this(assetLoader(context))

    private val json = Json { ignoreUnknownKeys = true }
    private val cache = mutableMapOf<SummarySource, BookIntrosPayload?>()

    private suspend fun get(source: SummarySource): BookIntrosPayload? = withContext(Dispatchers.IO) {
        if (source in cache) return@withContext cache[source]
        val resource = source.introResourceName ?: run {
            cache[source] = null
            return@withContext null
        }
        val parsed = runCatching {
            loadResource(resource)?.let { json.decodeFromString<BookIntrosPayload>(it) }
        }.getOrNull()
        cache[source] = parsed
        parsed
    }

    /**
     * Returns the "About this book" introduction for [book] under the selected
     * [source], falling back through the other sources so the entry point is
     * populated whenever any source covers the book. The returned attribution
     * reflects whichever source actually supplied the text.
     *
     * Returns null only when the source is OFF, or when no source has an entry.
     */
    suspend fun bookIntroduction(book: String, source: SummarySource): ResolvedBookIntro? {
        if (source == SummarySource.OFF) return null

        // Try the chosen source first, then the rest in the same order as iOS:
        // SwiftBible (only home of the apocrypha/pseudepigrapha intros), then
        // the two public-domain commentaries for any canonical gaps.
        val order = listOf(source, SummarySource.SWIFT_BIBLE, SummarySource.MATTHEW_HENRY, SummarySource.JFB)
        val seen = mutableSetOf<SummarySource>()
        for (candidate in order) {
            if (!seen.add(candidate)) continue
            val payload = get(candidate) ?: continue
            val intro = payload.bookIntros[book] ?: continue
            if (intro.paragraphs.isEmpty()) continue
            return ResolvedBookIntro(intro = intro, attribution = payload.source)
        }
        return null
    }

    companion object {
        private fun assetLoader(context: Context): (String) -> String? = { name ->
            runCatching {
                context.assets.open("$name.json").bufferedReader().use { it.readText() }
            }.getOrNull()
        }
    }
}
