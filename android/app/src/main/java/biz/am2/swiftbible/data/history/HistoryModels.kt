package biz.am2.swiftbible.data.history

data class HistorySection(
    val id: String,
    val title: String,
    val subtitle: String,
    val era: String,
    val emoji: String,
    val articles: List<HistoryArticle>,
)

data class HistoryArticle(
    val id: String,
    val title: String,
    val subtitle: String,
    val era: String,
    val estimatedMinutes: Int,
    val body: List<BodyBlock>,
    val pullQuotes: List<PullQuote> = emptyList(),
    val sources: List<HistorySource> = emptyList(),
    val related: List<String> = emptyList(),
)

sealed class BodyBlock {
    data class Paragraph(val text: String) : BodyBlock()
    data class Heading(val text: String) : BodyBlock()
    data class Quote(val text: String, val attribution: String) : BodyBlock()
    data class BulletList(val items: List<String>) : BodyBlock()
    data class Timeline(val entries: List<TimelineEntry>) : BodyBlock()
    object Divider : BodyBlock()
}

data class TimelineEntry(val year: String, val event: String)

data class PullQuote(
    val text: String,
    val attribution: String,
    val context: String? = null,
)

data class HistorySource(
    val title: String,
    val author: String? = null,
    val kind: SourceKind,
    val url: String? = null,
    val note: String? = null,
)

enum class SourceKind(val label: String) {
    PRIMARY("Primary"),
    SCHOLARLY("Scholarly"),
    ENCYCLOPEDIA("Reference"),
    SCRIPTURE("Scripture"),
}
