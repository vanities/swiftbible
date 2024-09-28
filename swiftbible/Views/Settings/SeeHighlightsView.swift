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

    @Binding var selectedTab: Tabs

    var body: some View {
        VStack {
            if highlightedVerses.isEmpty {
                Text("No Highlights saved")

            } else {
                List {
                    ForEach(highlightedVerses) { highlightedVerse in
                        Button(action: {
                            selectedTab = .bible
                            appViewModel.navigateToVerse(
                                bookName: highlightedVerse.book,
                                chapterNumber: highlightedVerse.chapter,
                                verseNumber: highlightedVerse.startingVerse
                            )
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
            }
        }
        .navigationBarTitle("Highlighted Verses")
    }
}


#Preview {
    SeeHighlightsView(selectedTab: .constant(.bible))
        .environment(UserViewModel())
}
