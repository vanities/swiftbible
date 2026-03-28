import Foundation

@MainActor
class AppIntentNavigator {
    static let shared = AppIntentNavigator()

    var onNavigateToBook: ((String) -> Void)?
    var onNavigateToSearch: ((String) -> Void)?
    var onNavigateToVerse: ((String, Int, Int) -> Void)?

    func navigateToBook(_ bookName: String) {
        onNavigateToBook?(bookName)
    }

    func navigateToSearch(query: String) {
        onNavigateToSearch?(query)
    }

    func navigateToVerse(bookName: String, chapter: Int, verse: Int) {
        onNavigateToVerse?(bookName, chapter, verse)
    }
}
