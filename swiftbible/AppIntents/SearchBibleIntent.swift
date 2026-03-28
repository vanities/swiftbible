import AppIntents

struct SearchBibleIntent: AppIntent {
    static var title: LocalizedStringResource = "Search the Bible"
    static var description: IntentDescription = "Searches the Bible for a phrase or word in SwiftBible."
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Query")
    var query: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let results = performSearch(query: query)
        AppIntentNavigator.shared.navigateToSearch(query: query)
        return .result(value: results)
    }

    private func performSearch(query: String) -> Int {
        let lowercased = query.lowercased()
        let books = BibleService.shared.fetchBibleData(version: .kjv)
        var count = 0
        for book in books.oldTestament + books.newTestament {
            for chapter in book.chapters {
                for paragraph in chapter.paragraphs where paragraph.text.lowercased().contains(lowercased) {
                    count += 1
                }
            }
        }
        return count
    }
}
