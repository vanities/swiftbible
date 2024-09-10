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
    let chapter: Chapter

    @State private var isHiding = false
    @State private var selectedParagraph: Paragraph?
    @State private var showActionSheet = false
    @State private var alreadyHighlighted: HighlightedVerse?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(
                        chapter.paragraphs,
                        id: \.startingVerse
                    ) { paragraph in
                        HStack(alignment: .top) {
                            Text("\(paragraph.startingVerse)")
                                .font(.footnote)
                                .foregroundColor(.gray)
                            ParagraphView(
                                firstVerseNumber: paragraph.startingVerse,
                                paragraph: paragraph.text
                            )
                            .background {
                                highlightedVerses.contains { $0.book == book.name && $0.startingVerse == paragraph.startingVerse } ? Color.yellow : .clear
                            }
                            .underline(selectedParagraph == paragraph)
                            .onLongPressGesture {
                                selectedParagraph = paragraph
                                alreadyHighlighted = highlightedVerses.first(where: { $0.book == book.name && $0.startingVerse == selectedParagraph!.startingVerse })
                                showActionSheet = true
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
            Text("\(book.name) \(chapter.number)")
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                if isHiding {
                    isHiding.toggle()
                }
            }
        )
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Selected Verse \(book.name) \(chapter.number): \(selectedParagraph?.startingVerse ?? 0)"), buttons: [
                .default(Text("Copy")) {
                    UIPasteboard.general.string = getStringFromSelectedParagraph()
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                },
                .default(Text("Highlight")) {
                    guard selectedParagraph != nil else { return }
                    let highlightedVerse = HighlightedVerse(
                        book: book.name,
                        startingVerse: selectedParagraph!.startingVerse
                    )

                    if let alreadyHighlightedVerse = alreadyHighlighted {
                        context.delete(alreadyHighlightedVerse)
                    } else {
                        context.insert(highlightedVerse)
                    }
                    do {
                        try context.save()
                    } catch {
                        print(error.localizedDescription)
                    }
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                },
                .default(Text("Share")) {
                    let shareText = getStringFromSelectedParagraph()
                    let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
                    }
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                },
                .cancel()
            ])
        }
    }

    func getStringFromSelectedParagraph() -> String {
        guard selectedParagraph != nil else { return "" }
        return "\(book.name) Chapter \(chapter.number) \(selectedParagraph!.startingVerse): \(selectedParagraph!.text)"
    }
}

#Preview {
    ChapterDetailView(book: Book.genesis, chapter: .init(number: 1, paragraphs: [.init(startingVerse: 1, text: "testing")]))
}
