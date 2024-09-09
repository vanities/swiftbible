//
//  ChapterDetailView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI
import SwiftData

struct ChapterDetailView: View {
    @Query private var highlightedVerses: [HighlightedVerse] = []
    @Environment(\.modelContext) private var context
    let book: Book
    let chapter: String

    @State private var isHiding = false
    @State private var selectedText = Set<String>()
    @State private var showActionSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(
                        book.chapters[chapter]?.sorted(by: { Int($0.key)! < Int($1.key)! }) ?? [],
                        id: \.key
                    ) { verse in
                        HStack(alignment: .top) {
                            Text(verse.key)
                                .font(.footnote)
                                .foregroundColor(.gray)
                            ParagraphView(
                                firstVerseNumber: verse.key,
                                paragraph: verse.value,
                                selectedText: $selectedText
                            )
                            .background {
                                highlightedVerses.contains { $0.book == book.name && $0.startingVerse == verse.key } ? Color.yellow : .clear
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
        .simultaneousGesture(
            TapGesture().onEnded {
                if isHiding {
                    isHiding.toggle()
                }
            }
        )
        .onLongPressGesture {
            if !selectedText.isEmpty {
                showActionSheet = true
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Selected \(selectedText.count > 1 ? "verses" : "Verse") \(book.name) \(chapter): \(selectedText.joined(separator: ","))"), buttons: [
                .default(Text("Copy")) {

                    var copiedString = "\(book.name) \(chapter) "
                    let selectedVerses = book.chapters[chapter]?.filter({ selectedText.contains($0.key) })

                    selectedVerses?.forEach { verse in
                        copiedString += "\(verse.key) \(verse.value)"
                    }

                    UIPasteboard.general.string = copiedString
                    selectedText = Set<String>()
                },
                .default(Text("Highlight")) {
                    selectedText.forEach { startingVerse in
                        let highlightedVerse = HighlightedVerse(
                            book: book.name,
                            startingVerse: startingVerse
                        )

                        let alreadyHighlighted = highlightedVerses.contains { $0.book == book.name && $0.startingVerse == startingVerse }

                        if alreadyHighlighted {
                            context.delete(highlightedVerse)
                        } else {
                            context.insert(highlightedVerse)
                        }
                        do {
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    selectedText = Set<String>()
                },
                .cancel()
            ])
        }
    }
}

#Preview {
    ChapterDetailView(book: Book.genesis, chapter: "1")
}
