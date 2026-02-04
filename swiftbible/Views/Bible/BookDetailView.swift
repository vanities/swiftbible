//
//  Bible.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI

struct BookDetailView: View {
    @Environment(AppViewModel.self) private var appViewModel

    // Store only the book name - actual data derived from current version
    let bookName: String

    init(book: Book) {
        self.bookName = book.name
    }

    // Computed property that always reflects the current version
    private var currentBook: Book {
        BibleService.shared.fetchBook(named: bookName, version: appViewModel.selectedVersion)
            ?? Book(name: bookName, description: "", chapters: [])
    }

    var body: some View {
        VStack(spacing: 0) {
            List(currentBook.chapters, id: \.self) { chapter in
                NavigationLink(destination: ChapterDetailView(book: currentBook, chapter: chapter)) {
                    NavigationTitle(name: "Chapter \(chapter.number)", description: chapterSummaries[currentBook.name]?[String(chapter.number)])
                }
            }
        }
        .navigationTitle(currentBook.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    BookDetailView(book: Book.genesis)
}
