package biz.am2.swiftbible.data.history

object ChurchHistoryContent {
    val allSections: List<HistorySection> = listOf(
        AncientIsraelHistory.ancientIsrael,
        IntertestamentalHistory.intertestamental,
        HebrewBibleHistory.hebrewBible,
        OriginsHistory.origins,
        EarlyChurchHistory.earlyChurch,
        SplitsHistory.splits,
        DenominationsHistory.denominations,
        PracticesHistory.practices,
        FurtherReadingHistory.further,
    )

    fun article(id: String): HistoryArticle? =
        allSections.firstNotNullOfOrNull { section -> section.articles.firstOrNull { it.id == id } }

    fun sectionFor(articleId: String): HistorySection? =
        allSections.firstOrNull { section -> section.articles.any { it.id == articleId } }
}
