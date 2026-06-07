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
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.system.rawValue
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20
    @Environment(\.colorScheme) private var colorScheme

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

    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRaw) ?? .system
    }

    // The "About this book" introduction for the current book under the
    // selected source, or nil when summaries are off or no source covers it.
    private var bookIntro: ResolvedBookIntro? {
        SummariesService.shared.bookIntroduction(book: bookName, source: summarySource)
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                if let bookIntro {
                    NavigationLink(destination: BookIntroView(bookName: currentBook.name, resolved: bookIntro)) {
                        aboutThisBookRow
                    }
                    .readingThemeRow(readingTheme)
                    .accessibilityIdentifier("AboutThisBookRow")
                }

                ForEach(currentBook.chapters, id: \.self) { chapter in
                    NavigationLink(destination: ChapterDetailView(book: currentBook, chapter: chapter)) {
                        NavigationTitle(
                            name: "Chapter \(chapter.number)",
                            description: SummariesService.shared.chapterTitle(
                                book: currentBook.name,
                                chapter: chapter.number,
                                source: summarySource
                            ),
                            tint: readChapters.contains(chapter.number) ? .accentColor : nil
                        )
                    }
                    .readingThemeRow(readingTheme)
                }
            }
            .readingThemeScreen(readingTheme, colorScheme: colorScheme)
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

    // First row of the chapter list: an entry point into the book's
    // "About this book" introduction.
    private var aboutThisBookRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed")
                .foregroundStyle(Color.accentColor)
                .font(.body)
            VStack(alignment: .leading) {
                Text("About this book")
                    .foregroundStyle(Color.accentColor)
                Text("Author, history & purpose")
                    .font(.footnote)
                    .fontWeight(.light)
            }
        }
        .font(Font.custom(fontName, size: CGFloat(fontSize), relativeTo: .body))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("About this book — author, history and purpose")
    }
}

#Preview {
    BookDetailView(book: Book.genesis)
}
