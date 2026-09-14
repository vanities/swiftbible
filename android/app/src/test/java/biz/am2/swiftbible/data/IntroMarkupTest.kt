package biz.am2.swiftbible.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Mirrors the iOS `IntroMarkup` tests (ios/swiftbibleTests/IntroMarkupTests.swift).
 * The "About this book" intros carry a two-construct markup written by
 * python_parser/parse_book_intros.py: "## " headings and "**bold**" runs. A
 * stray "**" must never render as literal asterisks or embolden the rest of a
 * paragraph.
 */
class IntroMarkupTest {

    @Test
    fun `a heading paragraph yields its title`() {
        assertEquals("Where Job Lived", IntroMarkup.heading("## Where Job Lived"))
    }

    @Test
    fun `a body paragraph is not a heading`() {
        assertNull(IntroMarkup.heading("Uz, according to Gesenius, means a light soil."))
        assertNull(IntroMarkup.heading("##No space is not a heading"))
    }

    @Test
    fun `plain text is one run`() {
        val text = "As to the name Job—repentance—it was common."
        assertEquals(listOf(IntroMarkup.Run(text, bold = false)), IntroMarkup.runs(text))
    }

    @Test
    fun `bold runs alternate with plain ones`() {
        assertEquals(
            listOf(
                IntroMarkup.Run("we must enquire, ", false),
                IntroMarkup.Run("I.", true),
                IntroMarkup.Run(" Into the divine authority of it. ", false),
                IntroMarkup.Run("II.", true),
                IntroMarkup.Run(" As to", false),
            ),
            IntroMarkup.runs("we must enquire, **I.** Into the divine authority of it. **II.** As to"),
        )
    }

    @Test
    fun `a paragraph opening in bold`() {
        assertEquals(
            listOf(IntroMarkup.Run("II.", true), IntroMarkup.Run(" To lead to Christ", false)),
            IntroMarkup.runs("**II.** To lead to Christ"),
        )
    }

    @Test
    fun `an unpaired marker stays literal`() {
        assertEquals(
            listOf(
                IntroMarkup.Run("The ", false),
                IntroMarkup.Run("time of writing", true),
                IntroMarkup.Run(" was 2 ** 3", false),
            ),
            IntroMarkup.runs("The **time of writing** was 2 ** 3"),
        )
    }

    @Test
    fun `runs reassemble the text without markup`() {
        val paragraph = "His **purpose**, then: **(1)** to defend; **(2)** to warn."
        assertEquals(
            paragraph.replace("**", ""),
            IntroMarkup.runs(paragraph).joinToString("") { it.text },
        )
    }
}
