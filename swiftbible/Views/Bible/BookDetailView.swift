//
//  Bible.swift
//  swiftbible
//
//  Created on 9/1/24.
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
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    BookDetailView(book: Book.genesis)
}
