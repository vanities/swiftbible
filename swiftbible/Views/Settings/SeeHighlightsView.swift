//
//  SeeHighlightsView.swift
//  swiftbible
//
//  Created on 9/11/24.
//

import SwiftUI
import SwiftData


struct SeeHighlightsView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

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
                                Text("Created: \(highlightedVerse.created.formatted(date: .long, time: .omitted))")
                                    .foregroundColor(.gray)
                            }
                            .font(Font.custom(fontName, size: CGFloat(fontSize)))
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
