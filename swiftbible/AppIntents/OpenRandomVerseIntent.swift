import AppIntents

struct OpenRandomVerseIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Random Verse"
    static var description: IntentDescription = "Opens a random Bible verse in SwiftBible for inspiration."
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let books = BibleService.shared.fetchBibleData(version: .kjv)
        let allBooks = books.oldTestament + books.newTestament
        guard let book = allBooks.randomElement(),
              let chapter = book.chapters.randomElement(),
              let paragraph = chapter.paragraphs.randomElement() else {
            return .result()
        }
        AppIntentNavigator.shared.navigateToVerse(
            bookName: book.name,
            chapter: chapter.number,
            verse: paragraph.startingVerse
        )
        return .result()
    }
}
