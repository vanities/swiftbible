package biz.am2.swiftbible.data

/**
 * Static chapter counts for the 66-book Protestant canon. Used by the
 * Progress screen's book-completion grid and by BadgeService when
 * evaluating "Books completed" thresholds and collectible book sets.
 * Mirrors iOS CanonicalBibleBooks.swift.
 */
object CanonicalBibleBooks {
    data class Entry(val name: String, val totalChapters: Int)

    val oldTestament: List<Entry> = listOf(
        Entry("Genesis", 50), Entry("Exodus", 40), Entry("Leviticus", 27), Entry("Numbers", 36),
        Entry("Deuteronomy", 34), Entry("Joshua", 24), Entry("Judges", 21), Entry("Ruth", 4),
        Entry("1 Samuel", 31), Entry("2 Samuel", 24), Entry("1 Kings", 22), Entry("2 Kings", 25),
        Entry("1 Chronicles", 29), Entry("2 Chronicles", 36), Entry("Ezra", 10), Entry("Nehemiah", 13),
        Entry("Esther", 10), Entry("Job", 42), Entry("Psalms", 150), Entry("Proverbs", 31),
        Entry("Ecclesiastes", 12), Entry("Song of Solomon", 8), Entry("Isaiah", 66), Entry("Jeremiah", 52),
        Entry("Lamentations", 5), Entry("Ezekiel", 48), Entry("Daniel", 12), Entry("Hosea", 14),
        Entry("Joel", 3), Entry("Amos", 9), Entry("Obadiah", 1), Entry("Jonah", 4),
        Entry("Micah", 7), Entry("Nahum", 3), Entry("Habakkuk", 3), Entry("Zephaniah", 3),
        Entry("Haggai", 2), Entry("Zechariah", 14), Entry("Malachi", 4),
    )

    val newTestament: List<Entry> = listOf(
        Entry("Matthew", 28), Entry("Mark", 16), Entry("Luke", 24), Entry("John", 21),
        Entry("Acts", 28), Entry("Romans", 16), Entry("1 Corinthians", 16), Entry("2 Corinthians", 13),
        Entry("Galatians", 6), Entry("Ephesians", 6), Entry("Philippians", 4), Entry("Colossians", 4),
        Entry("1 Thessalonians", 5), Entry("2 Thessalonians", 3), Entry("1 Timothy", 6),
        Entry("2 Timothy", 4), Entry("Titus", 3), Entry("Philemon", 1), Entry("Hebrews", 13),
        Entry("James", 5), Entry("1 Peter", 5), Entry("2 Peter", 3), Entry("1 John", 5),
        Entry("2 John", 1), Entry("3 John", 1), Entry("Jude", 1), Entry("Revelation", 22),
    )

    val all: List<Entry> = oldTestament + newTestament

    val shortNames: Map<String, String> = mapOf(
        "Genesis" to "Gen", "Exodus" to "Exo", "Leviticus" to "Lev", "Numbers" to "Num",
        "Deuteronomy" to "Deut", "Joshua" to "Josh", "Judges" to "Judg", "Ruth" to "Ruth",
        "1 Samuel" to "1 Sam", "2 Samuel" to "2 Sam", "1 Kings" to "1 Kgs", "2 Kings" to "2 Kgs",
        "1 Chronicles" to "1 Chr", "2 Chronicles" to "2 Chr", "Ezra" to "Ezra",
        "Nehemiah" to "Neh", "Esther" to "Est", "Job" to "Job", "Psalms" to "Pss",
        "Proverbs" to "Prov", "Ecclesiastes" to "Eccl", "Song of Solomon" to "Song",
        "Isaiah" to "Isa", "Jeremiah" to "Jer", "Lamentations" to "Lam", "Ezekiel" to "Ezek",
        "Daniel" to "Dan", "Hosea" to "Hos", "Joel" to "Joel", "Amos" to "Amos",
        "Obadiah" to "Obad", "Jonah" to "Jon", "Micah" to "Mic", "Nahum" to "Nah",
        "Habakkuk" to "Hab", "Zephaniah" to "Zeph", "Haggai" to "Hag", "Zechariah" to "Zech",
        "Malachi" to "Mal", "Matthew" to "Matt", "Mark" to "Mark", "Luke" to "Luke",
        "John" to "John", "Acts" to "Acts", "Romans" to "Rom", "1 Corinthians" to "1 Cor",
        "2 Corinthians" to "2 Cor", "Galatians" to "Gal", "Ephesians" to "Eph",
        "Philippians" to "Phil", "Colossians" to "Col", "1 Thessalonians" to "1 Th",
        "2 Thessalonians" to "2 Th", "1 Timothy" to "1 Tim", "2 Timothy" to "2 Tim",
        "Titus" to "Titus", "Philemon" to "Phlm", "Hebrews" to "Heb", "James" to "Jas",
        "1 Peter" to "1 Pet", "2 Peter" to "2 Pet", "1 John" to "1 Jn", "2 John" to "2 Jn",
        "3 John" to "3 Jn", "Jude" to "Jude", "Revelation" to "Rev",
    )

    val apocryphaNames: List<String> = listOf(
        "Tobit", "Judith", "Additions to Esther", "Wisdom of Solomon", "Ecclesiasticus",
        "Baruch", "Letter of Jeremiah", "Prayer of Azariah", "Susanna", "Bel and the Dragon",
        "1 Maccabees", "2 Maccabees", "1 Esdras", "2 Esdras", "Prayer of Manasseh",
        "Psalm 151", "3 Maccabees", "4 Maccabees",
    )

    val enochSections: List<String> = listOf(
        "The Book of the Watchers", "The Book of Parables",
        "The Astronomical Book", "The Book of Dream Visions", "The Epistle of Enoch",
    )
}
