//
//  SearchDetailView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/28/24.
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
    @Binding var selectedTab: Tabs
    @Environment(AppViewModel.self) var appViewModel: AppViewModel
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
            List(searchResults) { result in
                Button(action: {
                    selectVerse(result)
                }) {
                    VStack(alignment: .leading) {
                        Text("\(result.bookName) \(result.chapterNumber):\(result.verseNumber)")
                            .font(.headline)
                        Text(result.verseText)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                }
            }
            .navigationTitle("Search")
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
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
        selectedTab = .bible
        appViewModel.navigateToVerse(
            bookName: result.bookName,
            chapterNumber: result.chapterNumber,
            verseNumber: result.verseNumber
        )
    }
}
