import Foundation

struct Bookmark: Equatable {
    let bookName: String
    let chapter: Int
    let verse: Int

    var isValid: Bool {
        !bookName.isEmpty && chapter > 0 && verse > 0
    }
}

enum BookmarkPreferences {
    static let bookKey = "bookmarkBookName"
    static let chapterKey = "bookmarkChapterNumber"
    static let verseKey = "bookmarkVerseNumber"

    static func currentBookmark() -> Bookmark? {
        let defaults = UserDefaults.standard
        let bookName = defaults.string(forKey: bookKey) ?? ""
        let chapter = defaults.integer(forKey: chapterKey)
        let verse = defaults.integer(forKey: verseKey)
        let bookmark = Bookmark(bookName: bookName, chapter: chapter, verse: verse)
        return bookmark.isValid ? bookmark : nil
    }

    static func setBookmark(bookName: String, chapter: Int, verse: Int) {
        let defaults = UserDefaults.standard
        defaults.set(bookName, forKey: bookKey)
        defaults.set(chapter, forKey: chapterKey)
        defaults.set(verse, forKey: verseKey)
    }

    static func clearBookmark() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: bookKey)
        defaults.removeObject(forKey: chapterKey)
        defaults.removeObject(forKey: verseKey)
    }
}
