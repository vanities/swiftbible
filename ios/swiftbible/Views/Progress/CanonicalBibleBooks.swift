//
//  CanonicalBibleBooks.swift
//  swiftbible
//

import Foundation

/// Static chapter counts for the 66-book Protestant canon. Used by the
/// Progress tab's book-completion grid; mirrors the canonical list with
/// minimum coupling to JSON-loaded book data. Apocrypha / Enoch / Jubilees
/// are intentionally excluded from this grid for visual clarity — they
/// already have their own toggles in Settings.
enum CanonicalBibleBooks {
    static let all: [(name: String, totalChapters: Int)] = oldTestament + newTestament

    static let oldTestament: [(name: String, totalChapters: Int)] = [
        ("Genesis", 50), ("Exodus", 40), ("Leviticus", 27), ("Numbers", 36), ("Deuteronomy", 34),
        ("Joshua", 24), ("Judges", 21), ("Ruth", 4), ("1 Samuel", 31), ("2 Samuel", 24),
        ("1 Kings", 22), ("2 Kings", 25), ("1 Chronicles", 29), ("2 Chronicles", 36),
        ("Ezra", 10), ("Nehemiah", 13), ("Esther", 10), ("Job", 42), ("Psalms", 150),
        ("Proverbs", 31), ("Ecclesiastes", 12), ("Song of Solomon", 8), ("Isaiah", 66),
        ("Jeremiah", 52), ("Lamentations", 5), ("Ezekiel", 48), ("Daniel", 12), ("Hosea", 14),
        ("Joel", 3), ("Amos", 9), ("Obadiah", 1), ("Jonah", 4), ("Micah", 7), ("Nahum", 3),
        ("Habakkuk", 3), ("Zephaniah", 3), ("Haggai", 2), ("Zechariah", 14), ("Malachi", 4)
    ]

    static let newTestament: [(name: String, totalChapters: Int)] = [
        ("Matthew", 28), ("Mark", 16), ("Luke", 24), ("John", 21), ("Acts", 28),
        ("Romans", 16), ("1 Corinthians", 16), ("2 Corinthians", 13), ("Galatians", 6),
        ("Ephesians", 6), ("Philippians", 4), ("Colossians", 4), ("1 Thessalonians", 5),
        ("2 Thessalonians", 3), ("1 Timothy", 6), ("2 Timothy", 4), ("Titus", 3),
        ("Philemon", 1), ("Hebrews", 13), ("James", 5), ("1 Peter", 5), ("2 Peter", 3),
        ("1 John", 5), ("2 John", 1), ("3 John", 1), ("Jude", 1), ("Revelation", 22)
    ]

    static let shortNames: [String: String] = [
        "Genesis": "Gen", "Exodus": "Exo", "Leviticus": "Lev", "Numbers": "Num",
        "Deuteronomy": "Deut", "Joshua": "Josh", "Judges": "Judg", "Ruth": "Ruth",
        "1 Samuel": "1 Sam", "2 Samuel": "2 Sam", "1 Kings": "1 Kgs", "2 Kings": "2 Kgs",
        "1 Chronicles": "1 Chr", "2 Chronicles": "2 Chr", "Ezra": "Ezra",
        "Nehemiah": "Neh", "Esther": "Est", "Job": "Job", "Psalms": "Pss",
        "Proverbs": "Prov", "Ecclesiastes": "Eccl", "Song of Solomon": "Song",
        "Isaiah": "Isa", "Jeremiah": "Jer", "Lamentations": "Lam", "Ezekiel": "Ezek",
        "Daniel": "Dan", "Hosea": "Hos", "Joel": "Joel", "Amos": "Amos",
        "Obadiah": "Obad", "Jonah": "Jon", "Micah": "Mic", "Nahum": "Nah",
        "Habakkuk": "Hab", "Zephaniah": "Zeph", "Haggai": "Hag", "Zechariah": "Zech",
        "Malachi": "Mal",
        "Matthew": "Matt", "Mark": "Mark", "Luke": "Luke", "John": "John",
        "Acts": "Acts", "Romans": "Rom", "1 Corinthians": "1 Cor", "2 Corinthians": "2 Cor",
        "Galatians": "Gal", "Ephesians": "Eph", "Philippians": "Phil",
        "Colossians": "Col", "1 Thessalonians": "1 Th", "2 Thessalonians": "2 Th",
        "1 Timothy": "1 Tim", "2 Timothy": "2 Tim", "Titus": "Titus", "Philemon": "Phlm",
        "Hebrews": "Heb", "James": "Jas", "1 Peter": "1 Pet", "2 Peter": "2 Pet",
        "1 John": "1 Jn", "2 John": "2 Jn", "3 John": "3 Jn", "Jude": "Jude",
        "Revelation": "Rev"
    ]
}
