//
//  Bible.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI

struct BookDetailView: View {
    let book: Book

    var body: some View {
        VStack(spacing: 0) {
            List(book.chapters, id: \.self) { chapter in
                NavigationLink(destination: ChapterDetailView(book: book, chapter: chapter)) {
                    NavigationTitle(name: "Chapter \(chapter.number)", description: chapterSummaries[book.name]?[String(chapter.number)])
                }
            }
        }
        .navigationTitle(
            Text(book.name)
        )
    }
}

#Preview {
    BookDetailView(book: Book.genesis)
}
