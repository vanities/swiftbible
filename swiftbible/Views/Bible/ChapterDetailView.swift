//
//  ChapterDetailView.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI
import SwiftData
import UIKit
import MJRefresh

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
    // Swipe navigation removed in favor of pull up/down

    @Query private var highlightedVerses: [HighlightedVerse] = []
    @Query private var notes: [Note] = []

    @Environment(\.presentationMode) var presentationMode
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var context

    let book: Book
    let chapter: Chapter
    @State private var currentChapter: Chapter

    init(book: Book, chapter: Chapter) {
        self.book = book
        self.chapter = chapter
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
    @State private var explanationRequest: VerseExplanationRequest?

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

    // Attach MJRefresh header/footer to the underlying UIScrollView
    private func configureRefresh(on scrollView: UIScrollView) {
        scrollView.alwaysBounceVertical = true
        #if DEBUG
        print("[MJRefresh] Configuring refresh. contentSize=\(scrollView.contentSize) bounds=\(scrollView.bounds.size)")
        #endif

        if previousChapter != nil {
            if scrollView.mj_header == nil {
                let header = MJRefreshNormalHeader { [weak scrollView] in
                    defer { scrollView?.mj_header?.endRefreshing() }
                    guard let prev = previousChapter else { return }
                    transitionForward = false
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentChapter = prev
                        scrollPosition = nil
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #if DEBUG
                    print("[MJRefresh] Triggered previous chapter to \(currentChapter.number)")
                    #endif
                }
                if let h = header as? MJRefreshNormalHeader {
                    h.lastUpdatedTimeLabel?.isHidden = true
                    h.stateLabel?.isHidden = true
                    h.setTitle("Pull for previous chapter", for: .idle)
                    h.setTitle("Release to go back", for: .pulling)
                    h.setTitle("Loading…", for: .refreshing)
                    // Increase drag threshold - higher value requires more drag (default is ~0)
                    h.ignoredScrollViewContentInsetTop = 30
                }
                scrollView.mj_header = header
            } else {
                #if DEBUG
                print("[MJRefresh] Header already attached")
                #endif
            }
        } else {
            scrollView.mj_header = nil
            #if DEBUG
            print("[MJRefresh] No previous chapter; header removed")
            #endif
        }

        if nextChapter != nil {
            if scrollView.mj_footer == nil {
                let footer = MJRefreshBackNormalFooter { [weak scrollView] in
                    defer { scrollView?.mj_footer?.endRefreshing() }
                    guard let next = nextChapter else { return }
                    transitionForward = true
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentChapter = next
                        scrollPosition = nil
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #if DEBUG
                    print("[MJRefresh] Triggered next chapter to \(currentChapter.number)")
                    #endif
                }
                if let f = footer as? MJRefreshBackNormalFooter {
                    f.setTitle("Pull for next chapter", for: .idle)
                    f.setTitle("Release to continue", for: .pulling)
                    f.setTitle("Loading…", for: .refreshing)
                    // Increase drag threshold - higher value requires more drag (default is ~0)
                    f.ignoredScrollViewContentInsetBottom = 30
                }
                scrollView.mj_footer = footer
            } else {
                #if DEBUG
                print("[MJRefresh] Footer already attached")
                #endif
            }
        } else {
            scrollView.mj_footer = nil
            #if DEBUG
            print("[MJRefresh] No next chapter; footer removed")
            #endif
        }
    }

    // Helper to resolve the UIScrollView used by SwiftUI ScrollView
    private struct ScrollViewResolver: UIViewRepresentable {
        let onResolve: (UIScrollView) -> Void
        func makeUIView(context: Context) -> UIView { UIView() }
        func updateUIView(_ uiView: UIView, context: Context) {
            DispatchQueue.main.async {
                if let scroll = findScrollView(from: uiView) {
                    #if DEBUG
                    print("[MJRefresh] Resolver found UIScrollView contentSize=\(scroll.contentSize) bounds=\(scroll.bounds.size)")
                    #endif
                    onResolve(scroll)
                } else {
                    #if DEBUG
                    print("[MJRefresh] Resolver could not find UIScrollView yet")
                    #endif
                }
            }
        }
        private func findScrollView(from view: UIView?) -> UIScrollView? {
            // Walk up to a common ancestor, then search down for UIScrollView
            var ancestor = view
            while let current = ancestor {
                if let scroll = current as? UIScrollView { return scroll }
                if let found = searchDescendants(forScrollIn: current) { return found }
                ancestor = current.superview
            }
            return nil
        }
        private func searchDescendants(forScrollIn view: UIView) -> UIScrollView? {
            for sub in view.subviews {
                if let s = sub as? UIScrollView { return s }
                if let found = searchDescendants(forScrollIn: sub) { return found }
            }
            return nil
        }
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
            .background(ScrollViewResolver { scroll in
                configureRefresh(on: scroll)
            })
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
                    guard selectedParagraph != nil else { return }
                    explanationRequest = VerseExplanationRequest(
                        bookName: book.name,
                        chapter: currentChapter.number,
                        startingVerse: selectedParagraph!.startingVerse,
                        translation: book.version.rawValue,
                        paragraphText: selectedParagraph!.text
                    )
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                    alreadyNoted = nil
                } label: {
                    Text("Explain")
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
        .sheet(item: $explanationRequest) { request in
            VerseExplanationSheet(request: request)
        }
        // Removed left/right swipe gesture navigation in favor of pull-to-refresh style
        .onAppear {
            updateScrollPositionForContext()
        }
        .onChange(of: chapter) { newChapter in
            if currentChapter.number != newChapter.number {
                currentChapter = newChapter
            }
            updateScrollPositionForContext()
        }
        .onChange(of: book) { _ in
            selectedParagraph = nil
            alreadyHighlighted = nil
            alreadyNoted = nil
            currentChapter = chapter
            updateScrollPositionForContext()
        }
        .onChange(of: currentChapter.number) { _ in
            // Clear transient state when chapter changes
            selectedParagraph = nil
            alreadyHighlighted = nil
            alreadyNoted = nil
            // Jump to the top of the new chapter
            updateScrollPositionForContext()
            #if DEBUG
            print("[MJRefresh] onChange chapter now \(currentChapter.number)")
            #endif
        }
        .onChange(of: appViewModel.selectedVerse?.verse) { _ in
            updateScrollPositionForContext()
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

    private func updateScrollPositionForContext() {
        guard let selected = appViewModel.selectedVerse else {
            scrollToTop()
            return
        }

        if selected.book == book && selected.chapter.number == currentChapter.number {
            DispatchQueue.main.async {
                scrollPosition = selected.verse
            }
        } else {
            scrollToTop()
        }
    }

    private func scrollToTop() {
        if let first = currentChapter.paragraphs.first?.startingVerse {
            DispatchQueue.main.async {
                scrollPosition = first
            }
        } else {
            scrollPosition = nil
        }
    }
}

#Preview {
    ChapterDetailView(book: Book.genesis, chapter: .init(number: 1, paragraphs: [.init(startingVerse: 1, text: "testing")]))
}
