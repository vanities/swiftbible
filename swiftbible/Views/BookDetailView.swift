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
            List(book.chapters.keys.sorted(by: { (key1, key2) -> Bool in
                    guard let intKey1 = Int(key1), let intKey2 = Int(key2) else {
                        return key1 < key2
                    }
                    return intKey1 < intKey2
                }
            ), id: \.self) { chapter in
                 NavigationLink(destination: ChapterDetailView(book: book, chapter: chapter)) {
                     Text("Chapter \(chapter)")
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
