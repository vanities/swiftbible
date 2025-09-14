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
    @AppStorage("showChapterPager") private var showChapterPager: Bool = false
    @AppStorage("enableSwipeNavigation") private var enableSwipeNavigation: Bool = false

    @Query private var highlightedVerses: [HighlightedVerse] = []
    @Query private var notes: [Note] = []

    @Environment(\.presentationMode) var presentationMode
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var context

    let book: Book
    @State private var currentChapter: Chapter

    init(book: Book, chapter: Chapter) {
        self.book = book
        _currentChapter = State(initialValue: chapter)
    }

    @State private var showNavAndTab = true
    @State private var selectedParagraph: Paragraph?
    @State private var showActionSheet = false
    @State private var showNoteModal = false
    @State private var showVerseInfoModal = false
    @State private var alreadyHighlighted: HighlightedVerse?
    @State private var alreadyNoted: Note?
    @State private var scrollPosition: Int?
    @State private var transitionForward: Bool = true

    // Computed references to the next and previous chapters within the book
    private var currentChapterIndex: Int? {
        book.chapters.firstIndex { $0.number == currentChapter.number }
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
                        currentChapter.paragraphs,
                        id: \.startingVerse
                    ) { paragraph in
                        if let summary = summaries[book.name]?["\(currentChapter.number):\(paragraph.startingVerse)"] {
                            Text(summary)
                                .bold()
                                .padding(.top)
                                .font(Font.custom(fontName, size: CGFloat(fontSize+1)))
                        }
                        let isHighlighted = highlightedVerses.contains {
                            $0.version == book.version.rawValue &&
                            $0.book == book.name &&
                            $0.startingVerse == paragraph.startingVerse &&
                            $0.chapter == currentChapter.number
                        }

                        HStack(alignment: .top) {
                            VStack(alignment: .center) {
                                Text("\(paragraph.startingVerse)")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                if notes.contains(where: {
                                    $0.version == book.version.rawValue &&
                                    $0.book == book.name &&
                                    $0.chapter == currentChapter.number &&
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
                .id(currentChapter.number)
                .transition(.asymmetric(
                    insertion: .move(edge: transitionForward ? .trailing : .leading),
                    removal: .move(edge: transitionForward ? .leading : .trailing)
                ))
                .animation(.easeInOut(duration: 0.25), value: currentChapter.number)
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
        // Removed overlay NavigationLinks; navigation happens in-place
        .scrollPosition(id: $scrollPosition, anchor: .top)
        .navigationTitle("\(book.name) \(currentChapter.number)")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Selected Verse \(book.name) \(currentChapter.number):\(selectedParagraph?.startingVerse ?? 0)",
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
                        chapter: currentChapter.number,
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
                        if let prev = previousChapter {
                            transitionForward = false
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentChapter = prev
                                scrollPosition = nil
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                Spacer()
                if nextChapter != nil {
                    Button {
                        if let next = nextChapter {
                            transitionForward = true
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentChapter = next
                                scrollPosition = nil
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        .toolbar((showNavAndTab && showChapterPager) ? .visible : .hidden, for: .bottomBar)
        .simultaneousGesture(
            enableSwipeNavigation
                ? AnyGesture(
                    DragGesture()
                        .onEnded { value in
                            // If gesture begins near the left edge, treat it as a back-swipe attempt
                            // and do not trigger chapter navigation, even if it ends moving left.
                            let isEdgeBackAttempt = value.startLocation.x < 30
                            if isEdgeBackAttempt { return }

                            if value.translation.width < -50 {
                                if let next = nextChapter {
                                    transitionForward = true
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        currentChapter = next
                                        scrollPosition = nil
                                    }
                                }
                            } else if value.translation.width > 50 {
                                if let prev = previousChapter {
                                    transitionForward = false
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        currentChapter = prev
                                        scrollPosition = nil
                                    }
                                }
                            }
                        }
                )
                : AnyGesture(
                    // A never-recognized drag gesture acts as a no-op and won't steal back-swipe
                    DragGesture(minimumDistance: .greatestFiniteMagnitude)
                )
        )
        .onAppear {
            guard let book = appViewModel.selectedVerse?.book,
                  book == self.book,
                  let chapter = appViewModel.selectedVerse?.chapter,
                  chapter.number == self.currentChapter.number,
                  let verse = appViewModel.selectedVerse?.verse else { return }
            scrollPosition = verse
        }
        .onChange(of: currentChapter.number) { _ in
            // Clear transient state when chapter changes
            selectedParagraph = nil
            alreadyHighlighted = nil
            alreadyNoted = nil
            // Keep scrollPosition nil to start at top
            scrollPosition = nil
        }
    }

    func handleLongPress(paragraph: Paragraph) {
        selectedParagraph = paragraph
        alreadyHighlighted = highlightedVerses.first(where: {
            $0.version == book.version.rawValue &&
            $0.book == book.name &&
            $0.chapter == currentChapter.number &&
            $0.startingVerse == selectedParagraph!.startingVerse
        })
        alreadyNoted = notes.first(where: {
            $0.version == book.version.rawValue &&
            $0.book == book.name &&
            $0.chapter == currentChapter.number &&
            $0.startingVerse == selectedParagraph!.startingVerse
        })
        showActionSheet = true
    }

    func getStringFromSelectedParagraph() -> String {
        guard selectedParagraph != nil else { return "" }
        return "\(book.version.rawValue.uppercased()) Version \(book.name) Chapter \(currentChapter.number) \(selectedParagraph!.startingVerse): \(selectedParagraph!.text)"
    }

    func NoteModalViewView() -> some View {
        return NoteModalView(
            note: alreadyNoted != nil ? alreadyNoted! : Note(
                version: book.version.rawValue,
                book: book.name,
                chapter: currentChapter.number,
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
