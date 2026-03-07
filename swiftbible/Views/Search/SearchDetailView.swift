//
//  SearchDetailView.swift
//  swiftbible
//
//  Created on 9/28/24.
//

import SwiftUI

struct SearchResult: Identifiable {
    let id = UUID()
    let bookName: String
    let chapterNumber: Int
    let verseNumber: Int
    let verseText: String
}

struct SearchDetailView: View {
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    @Environment(AppViewModel.self) var appViewModel: AppViewModel

    @Binding var selectedTab: Tabs
    @State private var searchText: String = ""

    var searchResults: [SearchResult] {
        if searchText.isEmpty {
            return []
        } else {
            return performSearch()
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if searchResults.isEmpty && !searchText.isEmpty {
                    VStack {
                        Text("No results found.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                } else {
                    List(searchResults) { result in
                        Button(action: {
                            selectVerse(result)
                        }) {
                            VStack(alignment: .leading) {
                                Text("\(result.bookName) \(result.chapterNumber):\(result.verseNumber)")
                                    .bold()
                                ParagraphView(firstVerseNumber: result.verseNumber, paragraph: result.verseText)
                                    .lineLimit(5)
                            }
                            .font(Font.custom(fontName, size: CGFloat(fontSize)))
                        }
                    }
                    .buttonStyle(.plain)
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .navigationTitle("Search")
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .onSubmit(of: .search) {
            AnalyticsService.shared.capture(.searchPerformed, properties: [
                "query": searchText,
                "result_count": searchResults.count
            ])
        }
        .accessibilityIdentifier("SearchDetailView")
    }

    func performSearch() -> [SearchResult] {
        let lowercasedQuery = searchText.lowercased()
        var results: [SearchResult] = []
        guard let books = appViewModel.allBibleData else { return [] }

        for book in books {
            for chapter in book.chapters {
                for paragraph in chapter.paragraphs {
                    if paragraph.text.lowercased().contains(lowercasedQuery) {
                        let result = SearchResult(
                            bookName: book.name,
                            chapterNumber: chapter.number,
                            verseNumber: paragraph.startingVerse,
                            verseText: paragraph.text
                        )
                        results.append(result)
                    }
                }
            }
        }
        return results
    }

    func selectVerse(_ result: SearchResult) {
        AnalyticsService.shared.capture(.searchResultTapped, properties: [
            "book": result.bookName,
            "chapter": result.chapterNumber,
            "verse": result.verseNumber,
            "query": searchText
        ])
        selectedTab = .bible
        appViewModel.navigateToVerse(
            bookName: result.bookName,
            chapterNumber: result.chapterNumber,
            verseNumber: result.verseNumber
        )
    }
}
