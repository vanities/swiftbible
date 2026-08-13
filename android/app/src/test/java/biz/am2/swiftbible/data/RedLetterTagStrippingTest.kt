package biz.am2.swiftbible.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

/**
 * Mirrors the iOS `String.strippingRedLetterTags()` tests
 * (ios/swiftbibleTests/RedLetterTagStrippingTests.swift) — both platforms must
 * scrub `<JESUS>…</JESUS>` red-letter markup out of devotional text identically.
 *
 * Regression: the daily-devotional Edge Function's `selectRandomVerse()` handed
 * verse text to the prompt without stripping tags, so Aug 12, 2026 published
 * `"<JESUS>I am that bread of life. </JESUS>" John 6:48` verbatim.
 */
class RedLetterTagStrippingTest {

    @Test
    fun `strips tags from the blockquote that shipped broken`() {
        val shipped = """> *"<JESUS>I am that bread of life. </JESUS>"* **John 6:48**"""
        assertEquals(
            """> *"I am that bread of life. "* **John 6:48**""",
            shipped.stripRedLetterTags(),
        )
    }

    /**
     * 418 KJV paragraphs carry an inline verse number *between* two tags.
     * Stripping the whitespace hugging those tags would yield "thee;5:24Leave".
     */
    @Test
    fun `does not join words around an inline verse number`() {
        val inline = "against thee; </JESUS>5:24<JESUS> Leave there thy gift"
        assertEquals("against thee; 5:24 Leave there thy gift", inline.stripRedLetterTags())
    }

    @Test
    fun `keeps sentence spacing in mixed narration and red-letter text`() {
        val mixed = "And Jesus said, <JESUS>Follow me.</JESUS> Then he rose."
        assertEquals("And Jesus said, Follow me. Then he rose.", mixed.stripRedLetterTags())
    }

    @Test
    fun `handles a verse that is entirely red-letter`() {
        assertEquals("Peace be unto you.", "<JESUS>Peace be unto you.</JESUS>".stripRedLetterTags())
    }

    @Test
    fun `leaves ordinary devotional prose untouched`() {
        val prose = "He whispered \"hello\" and left.\n\n## The synagogue\n\nDust clings to ankles."
        assertEquals(prose, prose.stripRedLetterTags())
    }

    @Test
    fun `strips every occurrence in a multi-verse devotional`() {
        val multi = "<JESUS>I am the way.</JESUS> ... <JESUS>Abide in me.</JESUS>"
        val result = multi.stripRedLetterTags()
        assertFalse(result.contains("JESUS>"))
        assertEquals("I am the way. ... Abide in me.", result)
    }
}
