import Foundation

struct VerseInfo: Decodable {
    let version: String
    let book: String
    let chapter: Int
    let startingVerse: Int
    let text: String

    init(version: String, book: String, chapter: Int, startingVerse: Int, text: String) {
        self.version = version
        self.book = book
        self.chapter = chapter
        self.startingVerse = startingVerse
        self.text = text
    }
}
