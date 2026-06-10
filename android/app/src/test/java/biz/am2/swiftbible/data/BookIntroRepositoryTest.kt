package biz.am2.swiftbible.data

import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Exercises [BookIntroRepository] parsing and fallback resolution against
 * injected JSON strings, mirroring the asset files' schema. The fallback
 * chain must match iOS `SummariesService.bookIntroduction`:
 * selected source → SwiftBible Curated → Matthew Henry → JFB.
 */
class BookIntroRepositoryTest {

    private val mhcc = SummarySource.MATTHEW_HENRY.introResourceName!!
    private val jfb = SummarySource.JFB.introResourceName!!
    private val swiftBible = SummarySource.SWIFT_BIBLE.introResourceName!!

    private fun sourceJson(
        shortName: String,
        year: Int = 1900,
        books: Map<String, List<String>>,
    ): String {
        val intros = books.entries.joinToString(",") { (book, paragraphs) ->
            val paras = paragraphs.joinToString(",") { "\"$it\"" }
            """"$book": {"title": "Introduction to $book ($shortName)", "paragraphs": [$paras]}"""
        }
        return """
            {
              "source": {
                "name": "$shortName Commentary",
                "shortName": "$shortName",
                "year": $year,
                "license": "Public Domain",
                "attribution": "$shortName attribution"
              },
              "bookIntros": { $intros }
            }
        """.trimIndent()
    }

    private fun repository(files: Map<String, String>, loads: MutableList<String> = mutableListOf()) =
        BookIntroRepository { name ->
            loads.add(name)
            files[name]
        }

    @Test
    fun `parses title, paragraphs, and source attribution from the schema`() = runTest {
        val repo = repository(
            mapOf(mhcc to sourceJson("Matthew Henry", year = 1706, books = mapOf("Genesis" to listOf("First paragraph.", "Second paragraph.")))),
        )

        val resolved = repo.bookIntroduction("Genesis", SummarySource.MATTHEW_HENRY)!!

        assertEquals("Introduction to Genesis (Matthew Henry)", resolved.intro.title)
        assertEquals(listOf("First paragraph.", "Second paragraph."), resolved.intro.paragraphs)
        assertEquals("Matthew Henry Commentary", resolved.attribution.name)
        assertEquals("Matthew Henry", resolved.attribution.shortName)
        assertEquals(1706, resolved.attribution.year)
        assertEquals("Public Domain", resolved.attribution.license)
        assertEquals("Matthew Henry attribution", resolved.attribution.attribution)
    }

    @Test
    fun `unknown json keys are ignored`() = runTest {
        val json = """
            {
              "source": {
                "name": "X", "shortName": "X", "year": 2024,
                "license": "L", "attribution": "A", "extraSourceKey": true
              },
              "bookIntros": {
                "Genesis": {"title": "T", "paragraphs": ["P"], "extraIntroKey": 1}
              },
              "extraTopLevelKey": []
            }
        """.trimIndent()
        val repo = repository(mapOf(swiftBible to json))

        val resolved = repo.bookIntroduction("Genesis", SummarySource.SWIFT_BIBLE)!!

        assertEquals("T", resolved.intro.title)
        assertEquals(listOf("P"), resolved.intro.paragraphs)
    }

    @Test
    fun `selected source wins when it covers the book`() = runTest {
        val repo = repository(
            mapOf(
                jfb to sourceJson("JFB", books = mapOf("Genesis" to listOf("JFB text"))),
                swiftBible to sourceJson("SwiftBible", books = mapOf("Genesis" to listOf("SwiftBible text"))),
                mhcc to sourceJson("Matthew Henry", books = mapOf("Genesis" to listOf("MHCC text"))),
            ),
        )

        val resolved = repo.bookIntroduction("Genesis", SummarySource.JFB)!!

        assertEquals("JFB", resolved.attribution.shortName)
        assertEquals(listOf("JFB text"), resolved.intro.paragraphs)
    }

    @Test
    fun `falls back to swiftbible before the commentaries`() = runTest {
        // JFB selected but lacks Tobit; both SwiftBible and MHCC cover it —
        // SwiftBible must win because it precedes MHCC in the chain.
        val repo = repository(
            mapOf(
                jfb to sourceJson("JFB", books = mapOf("Genesis" to listOf("JFB text"))),
                swiftBible to sourceJson("SwiftBible", books = mapOf("Tobit" to listOf("SwiftBible text"))),
                mhcc to sourceJson("Matthew Henry", books = mapOf("Tobit" to listOf("MHCC text"))),
            ),
        )

        val resolved = repo.bookIntroduction("Tobit", SummarySource.JFB)!!

        assertEquals("SwiftBible", resolved.attribution.shortName)
        assertEquals(listOf("SwiftBible text"), resolved.intro.paragraphs)
    }

    @Test
    fun `falls back to matthew henry before jfb`() = runTest {
        val repo = repository(
            mapOf(
                swiftBible to sourceJson("SwiftBible", books = emptyMap()),
                mhcc to sourceJson("Matthew Henry", books = mapOf("Jude" to listOf("MHCC text"))),
                jfb to sourceJson("JFB", books = mapOf("Jude" to listOf("JFB text"))),
            ),
        )

        val resolved = repo.bookIntroduction("Jude", SummarySource.SWIFT_BIBLE)!!

        assertEquals("Matthew Henry", resolved.attribution.shortName)
    }

    @Test
    fun `falls back to jfb when no earlier source covers the book`() = runTest {
        val repo = repository(
            mapOf(
                mhcc to sourceJson("Matthew Henry", books = emptyMap()),
                swiftBible to sourceJson("SwiftBible", books = emptyMap()),
                jfb to sourceJson("JFB", books = mapOf("Acts" to listOf("JFB text"))),
            ),
        )

        val resolved = repo.bookIntroduction("Acts", SummarySource.MATTHEW_HENRY)!!

        assertEquals("JFB", resolved.attribution.shortName)
    }

    @Test
    fun `missing book in every source returns null`() = runTest {
        val repo = repository(
            mapOf(
                mhcc to sourceJson("Matthew Henry", books = mapOf("Genesis" to listOf("Text"))),
                swiftBible to sourceJson("SwiftBible", books = emptyMap()),
                jfb to sourceJson("JFB", books = emptyMap()),
            ),
        )

        assertNull(repo.bookIntroduction("Nonexistent Book", SummarySource.MATTHEW_HENRY))
    }

    @Test
    fun `off source returns null without loading anything`() = runTest {
        val loads = mutableListOf<String>()
        val repo = repository(
            mapOf(swiftBible to sourceJson("SwiftBible", books = mapOf("Genesis" to listOf("Text")))),
            loads,
        )

        assertNull(repo.bookIntroduction("Genesis", SummarySource.OFF))
        assertEquals(emptyList<String>(), loads)
    }

    @Test
    fun `entry with empty paragraphs is treated as missing`() = runTest {
        val repo = repository(
            mapOf(
                mhcc to sourceJson("Matthew Henry", books = mapOf("Ruth" to emptyList())),
                swiftBible to sourceJson("SwiftBible", books = mapOf("Ruth" to listOf("SwiftBible text"))),
            ),
        )

        val resolved = repo.bookIntroduction("Ruth", SummarySource.MATTHEW_HENRY)!!

        assertEquals("SwiftBible", resolved.attribution.shortName)
    }

    @Test
    fun `empty paragraphs in every source returns null`() = runTest {
        val repo = repository(
            mapOf(
                mhcc to sourceJson("Matthew Henry", books = mapOf("Ruth" to emptyList())),
                swiftBible to sourceJson("SwiftBible", books = mapOf("Ruth" to emptyList())),
                jfb to sourceJson("JFB", books = mapOf("Ruth" to emptyList())),
            ),
        )

        assertNull(repo.bookIntroduction("Ruth", SummarySource.MATTHEW_HENRY))
    }

    @Test
    fun `malformed source file is skipped and the chain continues`() = runTest {
        val repo = repository(
            mapOf(
                mhcc to "this is not json",
                swiftBible to sourceJson("SwiftBible", books = mapOf("Genesis" to listOf("Text"))),
            ),
        )

        val resolved = repo.bookIntroduction("Genesis", SummarySource.MATTHEW_HENRY)!!

        assertEquals("SwiftBible", resolved.attribution.shortName)
    }

    @Test
    fun `missing source file is skipped and the chain continues`() = runTest {
        // Loader returns null for MHCC and JFB; only SwiftBible exists.
        val repo = repository(
            mapOf(swiftBible to sourceJson("SwiftBible", books = mapOf("Genesis" to listOf("Text")))),
        )

        val resolved = repo.bookIntroduction("Genesis", SummarySource.MATTHEW_HENRY)!!

        assertEquals("SwiftBible", resolved.attribution.shortName)
    }

    @Test
    fun `sources are loaded once and cached`() = runTest {
        val loads = mutableListOf<String>()
        val repo = repository(
            mapOf(
                mhcc to sourceJson("Matthew Henry", books = mapOf("Genesis" to listOf("Text"))),
                swiftBible to sourceJson("SwiftBible", books = mapOf("Tobit" to listOf("Text"))),
            ),
            loads,
        )

        repo.bookIntroduction("Genesis", SummarySource.MATTHEW_HENRY)
        repo.bookIntroduction("Tobit", SummarySource.MATTHEW_HENRY)
        // Walks the whole chain (including the missing JFB file) twice; every
        // load — successful or failed — must happen exactly once.
        repo.bookIntroduction("Nonexistent Book", SummarySource.MATTHEW_HENRY)
        repo.bookIntroduction("Nonexistent Book", SummarySource.MATTHEW_HENRY)
        repo.bookIntroduction("Genesis", SummarySource.MATTHEW_HENRY)

        assertEquals(1, loads.count { it == mhcc })
        assertEquals(1, loads.count { it == swiftBible })
        assertEquals(1, loads.count { it == jfb })
    }
}
