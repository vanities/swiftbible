package biz.am2.swiftbible.model

import kotlinx.serialization.Serializable

@Serializable
data class Paragraph(
    val startingVerse: Int,
    val text: String,
)

@Serializable
data class Chapter(
    val number: Int,
    val paragraphs: List<Paragraph>,
)

@Serializable
data class Book(
    val name: String,
    val description: String = "",
    val chapters: List<Chapter>,
) {
    @kotlinx.serialization.Transient
    var testament: Testament = Testament.OLD

    @kotlinx.serialization.Transient
    var version: Version = Version.KJV
}

enum class Testament {
    OLD, NEW, APOCRYPHA, ENOCH, JUBILEES, TESTAMENTS, SECOND_ENOCH, DIDACHE, FIRST_CLEMENT;
}

enum class Version(val displayName: String, val shortName: String, val filename: String) {
    KJV("King James Version (KJV)", "KJV", "bible"),
    ASV("American Standard Version (ASV)", "ASV", "asv"),
    WEB("World English Bible (WEB)", "WEB", "web"),
    ORIGINAL("Original (Hebrew OT / Greek NT)", "Original", "hebrew");

    companion object {
        fun fromShortName(s: String): Version = entries.firstOrNull { it.shortName == s } ?: KJV
    }
}

object BookCatalog {
    val OLD_NAMES = listOf(
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
        "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
        "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
        "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
        "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah",
        "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel",
        "Amos", "Obadiah", "Jonah", "Micah", "Nahum",
        "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi"
    )

    val NEW_NAMES = listOf(
        "Matthew", "Mark", "Luke", "John", "Acts", "Romans",
        "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians", "Philippians",
        "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy",
        "2 Timothy", "Titus", "Philemon", "Hebrews", "James", "1 Peter",
        "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"
    )

    val APOCRYPHA_NAMES = listOf(
        "Tobit", "Judith", "Additions to Esther", "Wisdom of Solomon",
        "Ecclesiasticus", "Baruch", "Letter of Jeremiah", "Prayer of Azariah",
        "Susanna", "Bel and the Dragon", "1 Maccabees", "2 Maccabees",
        "1 Esdras", "2 Esdras", "Prayer of Manasseh", "Psalm 151",
        "3 Maccabees", "4 Maccabees"
    )
}
