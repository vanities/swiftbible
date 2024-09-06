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
        VStack(alignment: .center, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(
                        book.chapters[chapter]?.sorted(by: { Int($0.key)! < Int($1.key)! }) ?? [],
                            id: \.key
                    ) { verse in
                        HStack(alignment: .top) {
                            Group {
                                Text(verse.key)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                ParagraphView(paragraph: verse.value)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(
            Text("\(book.name) \(chapter)")
        )
    }
}

#Preview {
    ChapterDetailView(book: Book.genesis, chapter: "1")
}
