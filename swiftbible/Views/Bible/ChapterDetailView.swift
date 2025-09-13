//
//  ChapterDetailView.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI
import SwiftData

struct VerseInfoResponse: Decodable {
    let version: String
    let book: String
    let chapter: Int
    let starting_verse: Int
    let info: String
}

struct ChapterDetailView: View {
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20
    @AppStorage("highlightedColor") private var highlightedColor: String = "FFFFE0"
    @AppStorage("notedColor") private var notedColor: String = "00ff04"
    @AppStorage("hideNavAndTab") var hideNavAndTab = false

    @Query private var highlightedVerses: [HighlightedVerse] = []
    @Query private var notes: [Note] = []

    @Environment(\.presentationMode) var presentationMode
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var context

    let book: Book
    let chapter: Chapter

    @State private var showNavAndTab = true
    @State private var selectedParagraph: Paragraph?
    @State private var showActionSheet = false
    @State private var showNoteModal = false
    @State private var showVerseInfoModal = false
    @State private var alreadyHighlighted: HighlightedVerse?
    @State private var alreadyNoted: Note?
    @State private var scrollPosition: Int?

    // Navigation state
    @State private var navigateToNextChapter = false
    @State private var navigateToPreviousChapter = false

    // Computed references to the next and previous chapters within the book
    private var currentChapterIndex: Int? {
        book.chapters.firstIndex { $0.number == chapter.number }
    }

    private var nextChapter: Chapter? {
        guard let index = currentChapterIndex, index + 1 < book.chapters.count else { return nil }
        return book.chapters[index + 1]
    }

    private var previousChapter: Chapter? {
        guard let index = currentChapterIndex, index > 0 else { return nil }
        return book.chapters[index - 1]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(
                        chapter.paragraphs,
                        id: \.startingVerse
                    ) { paragraph in
                        if let summary = summaries[book.name]?["\(chapter.number):\(paragraph.startingVerse)"] {
                            Text(summary)
                                .bold()
                                .padding(.top)
                                .font(Font.custom(fontName, size: CGFloat(fontSize+1)))
                        }
                        let isHighlighted = highlightedVerses.contains {
                            $0.version == book.version.rawValue &&
                            $0.book == book.name &&
                            $0.startingVerse == paragraph.startingVerse &&
                            $0.chapter == chapter.number
                        }

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
                            .background { isHighlighted ? Color(hex: highlightedColor) : .clear }
                            .foregroundStyle(isHighlighted ? Color(hex: highlightedColor).accessibleFontColor : Color.primary)
                            .underline(selectedParagraph == paragraph)
                            .onLongPressGesture {
                                handleLongPress(paragraph: paragraph)
                            }
                        }
                    }
                }
                .scrollTargetLayout()
                .padding()
                .onAppear {
                    if hideNavAndTab {
                        withAnimation(.easeIn) {
                            showNavAndTab = false
                        }
                    }
                }
                .toolbar(showNavAndTab ? .visible : .hidden, for: .navigationBar)
                .toolbar(showNavAndTab ? .visible : .hidden, for: .tabBar)
            }
        }
        .overlay {
            // Hidden navigation links for programmatic chapter navigation
            Group {
                if let prev = previousChapter {
                    NavigationLink(isActive: $navigateToPreviousChapter) {
                        ChapterDetailView(book: book, chapter: prev)
                    } label: { EmptyView() }
                }
                if let next = nextChapter {
                    NavigationLink(isActive: $navigateToNextChapter) {
                        ChapterDetailView(book: book, chapter: next)
                    } label: { EmptyView() }
                }
            }
            .hidden()
        }
        .scrollPosition(id: $scrollPosition, anchor: .top)
        .navigationTitle("\(book.name) \(chapter.number)")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Selected Verse \(book.name) \(chapter.number):\(selectedParagraph?.startingVerse ?? 0)",
            isPresented: $showActionSheet,
            actions: {
                Button {
                    UIPasteboard.general.string = getStringFromSelectedParagraph()
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                } label: {
                    Text("Copy")
                }
                Button {
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
                } label: {
                    Text("\(alreadyHighlighted != nil ? "Unhighlight" : "Highlight")")
                }
                Button {
                    showNoteModal = true
                } label: {
                    Text("\(alreadyNoted != nil ? "View" : "Add") Note")
                }
                Button {
                    let shareText = getStringFromSelectedParagraph()
                    let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
                    }
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                } label: {
                    Text("Share")
                }
                Button("Cancel", role: .cancel) {
                    selectedParagraph = nil
                }

            },
            message: { }
        )
        .sheet(isPresented: $showNoteModal) {
            NoteModalViewView()
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                if previousChapter != nil {
                    Button {
                        navigateToPreviousChapter = true
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                Spacer()
                if nextChapter != nil {
                    Button {
                        navigateToNextChapter = true
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        .toolbar(showNavAndTab ? .visible : .hidden, for: .bottomBar)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        if nextChapter != nil {
                            navigateToNextChapter = true
                        }
                    } else if value.translation.width > 50 {
                        if previousChapter != nil {
                            navigateToPreviousChapter = true
                        }
                    }
                }
        )
        .onAppear {
            guard let book = appViewModel.selectedVerse?.book,
                  book == self.book,
                  let chapter = appViewModel.selectedVerse?.chapter,
                  chapter == self.chapter,
                  let verse = appViewModel.selectedVerse?.verse else { return }
            scrollPosition = verse
        }
    }

    func handleLongPress(paragraph: Paragraph) {
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

    func getStringFromSelectedParagraph() -> String {
        guard selectedParagraph != nil else { return "" }
        return "\(book.version.rawValue.uppercased()) Version \(book.name) Chapter \(chapter.number) \(selectedParagraph!.startingVerse): \(selectedParagraph!.text)"
    }

    func NoteModalViewView() -> some View {
        return NoteModalView(
            note: alreadyNoted != nil ? alreadyNoted! : Note(
                version: book.version.rawValue,
                book: book.name,
                chapter: chapter.number,
                startingVerse: selectedParagraph!.startingVerse,
                text: "",
                created: .now
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

#Preview {
    ChapterDetailView(book: Book.genesis, chapter: .init(number: 1, paragraphs: [.init(startingVerse: 1, text: "testing")]))
}




