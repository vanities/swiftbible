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
        VStack {
            Text(book.description)
                .font(.title)

            List(book.chapters.keys.sorted(), id: \.self) { chapter in
                 NavigationLink(destination: ChapterDetailView(book: book, chapter: chapter)) {
                     Text("Chapter \(chapter)")
                 }
             }
        }
    }
}

#Preview {
    BookDetailView(book: Book.genesis)
}
