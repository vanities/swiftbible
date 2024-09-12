//
//  SeeHighlightsView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/11/24.
//

import SwiftUI
import SwiftData


struct SeeHighlightsView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @Query private var highlightedVerses: [HighlightedVerse] = []

    @Binding var selectedTab: Int
    
    var body: some View {
        List {
            ForEach(highlightedVerses) { highlightedVerse in
                Button(action: {
                    guard let bibleData = appViewModel.allBibleData,
                        let book = bibleData.first(where: { $0.name == highlightedVerse.book }),
                          let chapter = book.chapters.first(where: { $0.number == highlightedVerse.chapter })
                    else { return }
                    selectedTab = 0
                    appViewModel.selectedVerse = SelectedVerse(
                        book: book,
                        chapter: chapter,
                        verse: highlightedVerse.startingVerse
                    )
                    appViewModel.showSelectedVerse = true
                }) {
                    VStack(alignment: .leading) {
                        Text("\(highlightedVerse.version.uppercased()) \(highlightedVerse.book) \(highlightedVerse.chapter):\(highlightedVerse.startingVerse)")
                            .font(.headline)
                        
                        Text("Created: \(highlightedVerse.created.formatted(date: .long, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationBarTitle("Highlighted Verses")
    }
}


#Preview {
    SeeHighlightsView(selectedTab: .constant(2))
        .environment(UserViewModel())
}
