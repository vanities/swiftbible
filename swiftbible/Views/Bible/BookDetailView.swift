//
//  Bible.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var context
    @AppStorage("summarySource") private var summarySourceRaw: String = defaultSummarySource.rawValue

    // Store only the book name - actual data derived from current version
    let bookName: String

    // Chapter numbers the user has read (scrolled to end + ≥30s); read rows recede.
    @State private var readChapters: Set<Int> = []

    init(book: Book) {
        self.bookName = book.name
    }

    // Computed property that always reflects the current version
    private var currentBook: Book {
        BibleService.shared.fetchBook(named: bookName, version: appViewModel.selectedVersion)
            ?? Book(name: bookName, description: "", chapters: [])
    }

    private var summarySource: SummarySource {
        SummarySource(rawValue: summarySourceRaw) ?? defaultSummarySource
    }

    var body: some View {
        VStack(spacing: 0) {
            List(currentBook.chapters, id: \.self) { chapter in
                NavigationLink(destination: ChapterDetailView(book: currentBook, chapter: chapter)) {
                    NavigationTitle(
                        name: "Chapter \(chapter.number)",
                        description: SummariesService.shared.chapterTitle(
                            book: currentBook.name,
                            chapter: chapter.number,
                            source: summarySource
                        )
                    )
                    .opacity(readChapters.contains(chapter.number) ? 0.4 : 1)
                }
            }
        }
        .navigationTitle(currentBook.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            readChapters = ReadingStatsService.shared.readChapterNumbers(forBook: bookName, in: context)
            AnalyticsService.shared.capture(.bookOpened, properties: [
                "book": currentBook.name,
                "testament": "\(currentBook.testament ?? .old)",
                "version": appViewModel.selectedVersion.rawValue,
                "chapters": currentBook.chapters.count
            ])
        }
    }
}

#Preview {
    BookDetailView(book: Book.genesis)
}
