package biz.am2.swiftbible.data

/**
 * Bible study notes source. Each source ships as a bundled JSON file under
 * `assets/`; sources that don't cover a particular book (e.g., Matthew Henry
 * has no entries for the Apocrypha or pseudepigrapha) fall back to the
 * SwiftBible Curated source so the picker never hides content.
 *
 * Mirrors `SummarySource` in iOS `SummariesService.swift`.
 */
enum class SummarySource(
    val id: String,
    val displayName: String,
    val resourceName: String?,
) {
    MATTHEW_HENRY("mhcc", "Matthew Henry", "summaries_mhcc"),
    JFB("jfb", "Jamieson-Fausset-Brown", "summaries_jfb"),
    SWIFT_BIBLE("swiftbible", "SwiftBible Curated", "summaries_swiftbible"),
    OFF("off", "Off", null),
    ;

    companion object {
        /** Matthew Henry fills every blank the original curated source has. */
        val Default: SummarySource = MATTHEW_HENRY

        fun fromId(id: String?): SummarySource =
            entries.firstOrNull { it.id == id } ?: Default
    }
}
