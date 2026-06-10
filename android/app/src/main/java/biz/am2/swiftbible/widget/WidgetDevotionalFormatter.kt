package biz.am2.swiftbible.widget

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Pure formatting helpers for the Daily Devotional home-screen widget.
 *
 * Mirrors the iOS widget's `cleanMarkdown` / `extractHeading` /
 * `devotionalTitle` logic (ios/swiftbibleWidget/DailyVerseWidget.swift) so
 * both platforms render identical previews from the same devotional markdown.
 */
object WidgetDevotionalFormatter {

    private const val PREVIEW_LIMIT = 300
    private const val DATE_SEPARATOR = " — "

    private val titleFormatter = DateTimeFormatter.ofPattern("EEEE, MMM d", Locale.ENGLISH)

    /** Date label shown on the widget, e.g. "Thursday, Mar 26". */
    fun dateTitle(date: LocalDate): String = date.format(titleFormatter)

    /**
     * Strip markdown formatting and extract the body paragraph for display.
     *
     * Uses the second paragraph (the body) when available, otherwise falls
     * back to the first, and truncates at [PREVIEW_LIMIT] characters on a
     * word boundary with a trailing ellipsis.
     */
    fun preview(message: String): String {
        val clean = message
            .replace("**", "")
            .replace("*", "")
            .replace("##", "")
            .replace("#", "")
            .replace("> ", "")
        val paragraphs = clean.split("\n\n")
            .map { it.trim() }
            .filter { it.isNotEmpty() }
        val body = when {
            paragraphs.size > 1 -> paragraphs[1]
            paragraphs.isNotEmpty() -> paragraphs.first()
            else -> clean
        }
        if (body.length <= PREVIEW_LIMIT) return body
        val truncated = body.take(PREVIEW_LIMIT)
        val lastSpace = truncated.lastIndexOf(' ')
        return if (lastSpace >= 0) {
            truncated.substring(0, lastSpace) + "..."
        } else {
            truncated + "..."
        }
    }

    /**
     * Extract the devotional heading (first paragraph), with the leading
     * date prefix (e.g. "March 30, 2026 — ") stripped at the first " — ".
     * Returns null when the message has no non-empty paragraphs.
     */
    fun heading(message: String): String? {
        val clean = message
            .replace("**", "")
            .replace("*", "")
            .replace("##", "")
            .replace("#", "")
        val first = clean.split("\n\n")
            .map { it.trim() }
            .firstOrNull { it.isNotEmpty() }
            ?: return null
        val separator = first.indexOf(DATE_SEPARATOR)
        return if (separator >= 0) first.substring(separator + DATE_SEPARATOR.length) else first
    }
}
