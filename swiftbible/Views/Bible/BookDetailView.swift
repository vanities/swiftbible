//
//  Bible.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI

struct BookDetailView: View {
    @AppStorage("fontSize") private var fontSize: Int = 20
    let book: Book

    var body: some View {
        VStack(spacing: 0) {
            List(book.chapters.keys.sorted(by: sorter), id: \.self) { chapter in
                 NavigationLink(destination: ChapterDetailView(book: book, chapter: chapter)) {
                     Text("Chapter \(chapter)")
                         .font(Font.system(size: CGFloat(fontSize)))
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
