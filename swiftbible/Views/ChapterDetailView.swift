//
//  ChapterDetailView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI

struct ChapterDetailView: View {
    let book: Book
    let chapter: String


    var body: some View {
        VStack(alignment: .center) {
            Text(book.name)
                .font(.title)

            Text("Chapter \(chapter)")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(book.chapters[chapter]!.enumerated().map { ($0, $1) }, id: \.1) { index, verse in
                        HStack(alignment: .top) {
                            Text("\(index + 1)")
                            Text(verse)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    ChapterDetailView(book: Book.genesis, chapter: "1")
}
