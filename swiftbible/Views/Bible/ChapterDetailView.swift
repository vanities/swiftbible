//
//  ChapterDetailView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI
import SwiftData

struct ChapterDetailView: View {
    @AppStorage("highlightedColor") private var highlightedColor: String = "FFFFE0"
    @AppStorage("notedColor") private var notedColor: String = "00ff04"

    @Query private var highlightedVerses: [HighlightedVerse] = []
    @Query private var notes: [Note] = []
    
    @Environment(\.modelContext) private var context

    let book: Book
    let chapter: Chapter

    @State private var isHiding = false
    @State private var selectedParagraph: Paragraph?
    @State private var showActionSheet = false
    @State private var showNoteModal = false
    @State private var alreadyHighlighted: HighlightedVerse?
    @State private var alreadyNoted: Note?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(
                        chapter.paragraphs,
                        id: \.startingVerse
                    ) { paragraph in
                        HStack(alignment: .top) {
                            VStack(alignment: .center) {
                                Text("\(paragraph.startingVerse)")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                if notes.contains(where: {
                                    $0.version == book.version.rawValue &&
                                    $0.book == book.name &&
                                    $0.chapter == chapter.number &&
                                    $0.startingVerse == paragraph.startingVerse
                                }) {
                                    Capsule()
                                        .fill(Color(hex: notedColor))
                                        .frame(width: 5)
                                }
                            }
                            ParagraphView(
                                firstVerseNumber: paragraph.startingVerse,
                                paragraph: paragraph.text
                            )
                            .background {
                                highlightedVerses.contains {
                                    $0.version == book.version.rawValue &&
                                    $0.book == book.name &&
                                    $0.startingVerse == paragraph.startingVerse &&
                                    $0.chapter == chapter.number
                                } ? Color(hex: highlightedColor) : .clear
                            }
                            .underline(selectedParagraph == paragraph)
                            .onLongPressGesture {
                                selectedParagraph = paragraph
                                alreadyHighlighted = highlightedVerses.first(where: {
                                    $0.version == book.version.rawValue &&
                                    $0.book == book.name &&
                                    $0.chapter == chapter.number &&
                                    $0.startingVerse == selectedParagraph!.startingVerse
                                })
                                alreadyNoted = notes.first(where: {
                                    $0.version == book.version.rawValue &&
                                    $0.book == book.name &&
                                    $0.chapter == chapter.number &&
                                    $0.startingVerse == selectedParagraph!.startingVerse
                                } )
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
            ActionSheetView()
        }
        .sheet(isPresented: $showNoteModal) {
            NoteModalView(
                note: alreadyNoted != nil ? alreadyNoted! : Note(
                    version: book.version.rawValue,
                    book: book.name,
                    chapter: chapter.number,
                    startingVerse: selectedParagraph!.startingVerse,
                    text: ""
                ),
                onSave: { note in
                    context.insert(note)
                    do {
                        try context.save()
                    } catch {
                        print(error.localizedDescription)
                    }
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                    showNoteModal = false
                },
                onCancel: {
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                    showNoteModal = false
                },
                onDelete: { note in
                    context.delete(note)
                    do {
                        try context.save()
                    } catch {
                        print(error.localizedDescription)
                    }
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                    showNoteModal = false
                }

            )
        }
    }

    func getStringFromSelectedParagraph() -> String {
        guard selectedParagraph != nil else { return "" }
        return "\(book.version) Version \(book.version) Version \(book.name) Chapter \(chapter.number) \(selectedParagraph!.startingVerse): \(selectedParagraph!.text)"
    }

    func ActionSheetView() -> ActionSheet {
        return ActionSheet(title: Text("Selected Verse \(book.name) \(chapter.number):\(selectedParagraph?.startingVerse ?? 0)"), buttons: [
            .default(Text("Copy")) {
                UIPasteboard.general.string = getStringFromSelectedParagraph()
                selectedParagraph = nil
                alreadyHighlighted = nil
            },
            .default(Text("\(alreadyHighlighted != nil ? "Unhighlight" : "Highlight")")) {
                guard selectedParagraph != nil else { return }
                let highlightedVerse = HighlightedVerse(
                    version: book.version.rawValue,
                    book: book.name,
                    chapter: chapter.number,
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
            .default(Text("\(alreadyNoted != nil ? "Update" : "Add") Note")) {
                showNoteModal = true
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

#Preview {
    ChapterDetailView(book: Book.genesis, chapter: .init(number: 1, paragraphs: [.init(startingVerse: 1, text: "testing")]))
}


struct NoteIndicatorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
