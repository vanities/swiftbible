package biz.am2.swiftbible.data

import biz.am2.swiftbible.model.BookCatalog

object CrossReference {
    private val BOOK_NAMES = (BookCatalog.OLD_NAMES + BookCatalog.NEW_NAMES + BookCatalog.APOCRYPHA_NAMES)
        .distinct()
        .sortedByDescending { it.length }

    private val NUMBERED_BOOK_REGEX = Regex(
        """\b(?:1|2|3|First|Second|Third|I|II|III)\s+(?:Samuel|Kings|Chronicles|Corinthians|Thessalonians|Timothy|Peter|John|Maccabees|Esdras|Clement)\s+(\d{1,3}):(\d{1,3})""",
        RegexOption.IGNORE_CASE,
    )
    private val PLAIN_BOOK_REGEX_TEMPLATE = """\b(%s)\s+(\d{1,3}):(\d{1,3})"""

    data class Match(val start: Int, val endExclusive: Int, val book: String, val chapter: Int, val verse: Int)

    fun findReferences(text: String): List<Match> {
        val matches = mutableListOf<Match>()

        // Match numbered books first (they overlap with plain "Samuel", etc., but are more specific)
        NUMBERED_BOOK_REGEX.findAll(text).forEach { m ->
            val full = m.value
            val parts = parseNumbered(full) ?: return@forEach
            val (book, chapter, verse) = parts
            matches.add(Match(m.range.first, m.range.last + 1, book, chapter, verse))
        }

        // Then plain books — only those without a leading number
        val plainBooks = BOOK_NAMES.filter { name ->
            !name.startsWith("1 ") && !name.startsWith("2 ") && !name.startsWith("3 ")
        }
        plainBooks.forEach { book ->
            val pattern = Regex(PLAIN_BOOK_REGEX_TEMPLATE.format(Regex.escape(book)))
            pattern.findAll(text).forEach { m ->
                val chapter = m.groupValues[2].toIntOrNull() ?: return@forEach
                val verse = m.groupValues[3].toIntOrNull() ?: return@forEach
                if (matches.none { it.start <= m.range.first && it.endExclusive > m.range.first }) {
                    matches.add(Match(m.range.first, m.range.last + 1, book, chapter, verse))
                }
            }
        }
        return matches.sortedBy { it.start }
    }

    private fun parseNumbered(text: String): Triple<String, Int, Int>? {
        val regex = Regex(
            """(1|2|3|First|Second|Third|I|II|III)\s+(\w+)\s+(\d+):(\d+)""",
            RegexOption.IGNORE_CASE,
        )
        val m = regex.matchEntire(text) ?: return null
        val numberWord = m.groupValues[1]
        val rest = m.groupValues[2]
        val chapter = m.groupValues[3].toIntOrNull() ?: return null
        val verse = m.groupValues[4].toIntOrNull() ?: return null
        val number = when (numberWord.lowercase()) {
            "1", "first", "i" -> 1
            "2", "second", "ii" -> 2
            "3", "third", "iii" -> 3
            else -> return null
        }
        val candidate = "$number $rest"
        val canonical = BOOK_NAMES.firstOrNull { it.equals(candidate, ignoreCase = true) } ?: return null
        return Triple(canonical, chapter, verse)
    }
}
