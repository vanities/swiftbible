package biz.am2.swiftbible.widget

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Exercises [WidgetDevotionalFormatter] against the behavior of the iOS
 * widget's `cleanMarkdown` / `extractHeading` / `devotionalTitle`
 * (ios/swiftbibleWidget/DailyVerseWidget.swift) — both platforms must render
 * the same preview, heading, and date label from the same devotional markdown.
 */
class WidgetDevotionalFormatterTest {

    private val devotional =
        "**June 10, 2026 — Psalm 23: The Lord Is My Shepherd**\n\n" +
            "> In Psalm 23, *David* paints a picture of God as a **shepherd** who provides.\n\n" +
            "## Reflection\n\n" +
            "Take a moment to rest in that promise."

    // MARK: - preview

    @Test
    fun `preview strips markdown markers`() {
        assertEquals(
            "In Psalm 23, David paints a picture of God as a shepherd who provides.",
            WidgetDevotionalFormatter.preview(devotional),
        )
    }

    @Test
    fun `preview prefers the second paragraph over the heading`() {
        val message = "First paragraph heading.\n\nSecond paragraph body.\n\nThird paragraph."

        assertEquals("Second paragraph body.", WidgetDevotionalFormatter.preview(message))
    }

    @Test
    fun `preview falls back to the only paragraph`() {
        assertEquals(
            "Just one paragraph today.",
            WidgetDevotionalFormatter.preview("Just one paragraph today."),
        )
    }

    @Test
    fun `preview truncates past 300 characters at a word boundary with ellipsis`() {
        // 51 five-letter words joined by spaces = 305 chars. The 300-char
        // prefix ends on the space after word 50, so the cut keeps exactly
        // 50 whole words and appends the ellipsis.
        val body = List(51) { "lorem" }.joinToString(" ")
        val message = "Heading.\n\n$body"

        val preview = WidgetDevotionalFormatter.preview(message)

        assertEquals(List(50) { "lorem" }.joinToString(" ") + "...", preview)
        assertTrue(preview.endsWith("lorem..."))
        assertEquals(302, preview.length)
    }

    @Test
    fun `preview keeps a body of exactly 300 characters untruncated`() {
        val body = "x".repeat(300)

        assertEquals(body, WidgetDevotionalFormatter.preview("Heading.\n\n$body"))
    }

    @Test
    fun `preview hard-cuts with ellipsis when no space exists before the limit`() {
        val body = "y".repeat(301)

        assertEquals(
            "y".repeat(300) + "...",
            WidgetDevotionalFormatter.preview("Heading.\n\n$body"),
        )
    }

    // MARK: - heading

    @Test
    fun `heading strips the date prefix at the first separator`() {
        assertEquals(
            "Psalm 23: The Lord Is My Shepherd",
            WidgetDevotionalFormatter.heading(devotional),
        )
    }

    @Test
    fun `heading strips only the first separator occurrence`() {
        val message = "June 1, 2026 — Holy Monday — Matthew 21:13: A House of Prayer\n\nBody."

        assertEquals(
            "Holy Monday — Matthew 21:13: A House of Prayer",
            WidgetDevotionalFormatter.heading(message),
        )
    }

    @Test
    fun `heading keeps the first paragraph when there is no date prefix`() {
        assertEquals(
            "A Word for Today",
            WidgetDevotionalFormatter.heading("**A Word for Today**\n\nBody text."),
        )
    }

    @Test
    fun `heading is null when the message is empty`() {
        assertNull(WidgetDevotionalFormatter.heading(""))
    }

    @Test
    fun `heading is null when the message is only whitespace`() {
        assertNull(WidgetDevotionalFormatter.heading("   \n\n  \n\n"))
    }

    // MARK: - dateTitle

    @Test
    fun `dateTitle formats as weekday comma short month day`() {
        assertEquals(
            "Thursday, Mar 26",
            WidgetDevotionalFormatter.dateTitle(LocalDate.of(2026, 3, 26)),
        )
    }

    @Test
    fun `dateTitle does not zero-pad the day`() {
        assertEquals(
            "Wednesday, Jun 3",
            WidgetDevotionalFormatter.dateTitle(LocalDate.of(2026, 6, 3)),
        )
    }
}
