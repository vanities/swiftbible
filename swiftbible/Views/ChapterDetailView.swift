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

    @State private var isHiding = false

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
                .onScrollingChange(onScrollingDown: {
                    isHiding = true
                }, onScrollingUp: {
                    isHiding = false
                }, onScrollingStopped: {
                })
            }
            .toolbar(isHiding ? .hidden : .visible, for: .navigationBar)
            .toolbar(isHiding ? .hidden : .visible, for: .tabBar)
            .animation(.easeIn, value: isHiding)
        }
        .navigationTitle(
            Text("\(book.name) \(chapter)")
        )
        .onTapGesture {
            isHiding.toggle()
        }
    }
}

#Preview {
    ChapterDetailView(book: Book.genesis, chapter: "1")
}
