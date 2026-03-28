import AppIntents

struct BibleBookEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Bible Book")
    static var defaultQuery = BibleBookQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static let allBooks: [BibleBookEntity] = {
        let names = Testament.oldNames + Testament.newNames
        return names.map { BibleBookEntity(id: $0, name: $0) }
    }()
}

struct BibleBookQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [BibleBookEntity] {
        BibleBookEntity.allBooks.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [BibleBookEntity] {
        BibleBookEntity.allBooks
    }
}

struct OpenBookIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Bible Book"
    static var description: IntentDescription = "Opens a specific book of the Bible in SwiftBible."
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Book")
    var book: BibleBookEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppIntentNavigator.shared.navigateToBook(book.name)
        return .result()
    }
}
