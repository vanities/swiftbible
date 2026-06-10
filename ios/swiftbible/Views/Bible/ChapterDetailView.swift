//
//  ChapterDetailView.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI
import SwiftData
import StoreKit
import UIKit

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
    @AppStorage(BookmarkPreferences.bookKey) private var bookmarkedBookName: String = ""
    @AppStorage(BookmarkPreferences.chapterKey) private var bookmarkedChapterNumber: Int = 0
    @AppStorage(BookmarkPreferences.verseKey) private var bookmarkedVerseNumber: Int = 0
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.system.rawValue
    @AppStorage("summarySource") private var summarySourceRaw: String = defaultSummarySource.rawValue

    private var summarySource: SummarySource {
        SummarySource(rawValue: summarySourceRaw) ?? defaultSummarySource
    }

    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRaw) ?? .system
    }
    // Swipe navigation removed in favor of pull up/down

    @Query private var highlightedVerses: [HighlightedVerse] = []
    @Query private var notes: [Note] = []

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) private var requestReview

    // Store only identifying info - the actual data is derived from current version
    let bookName: String
    let initialChapterNumber: Int
    @State private var currentChapterNumber: Int

    init(book: Book, chapter: Chapter) {
        self.bookName = book.name
        self.initialChapterNumber = chapter.number
        _currentChapterNumber = State(initialValue: chapter.number)
    }

    // Computed properties that always reflect the current version
    private var currentBook: Book {
        BibleService.shared.fetchBook(named: bookName, version: appViewModel.selectedVersion)
            ?? Book(name: bookName, description: "", chapters: [])
    }

    private var currentChapter: Chapter {
        currentBook.chapters.first { $0.number == currentChapterNumber }
            ?? Chapter(number: currentChapterNumber, paragraphs: [])
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

    private var supportsVersionSwitching: Bool {
        Testament.oldNames.contains(bookName) || Testament.newNames.contains(bookName)
    }

    // Computed references to the next and previous chapters within the book
    private var currentChapterIndex: Int? {
        currentBook.chapters.firstIndex { $0.number == currentChapterNumber }
    }

    private var nextChapter: Chapter? {
        guard let index = currentChapterIndex, index + 1 < currentBook.chapters.count else { return nil }
        return currentBook.chapters[index + 1]
    }

    private var previousChapter: Chapter? {
        guard let index = currentChapterIndex, index > 0 else { return nil }
        return currentBook.chapters[index - 1]
    }

    // Attach MJRefresh header/footer to the underlying UIScrollView
    private func configureRefresh(on scrollView: UIScrollView) {
        ChapterPullNavigation.configure(
            on: scrollView,
            hasPrevious: previousChapter != nil,
            hasNext: nextChapter != nil,
            onPrevious: goToPreviousChapter,
            onNext: goToNextChapter
        )
    }

    private func goToPreviousChapter() {
        guard let prev = previousChapter else { return }
        transitionForward = false
        withAnimation(.easeInOut(duration: 0.25)) {
            currentChapterNumber = prev.number
            scrollPosition = nil
        }
        #if DEBUG
        print("[MJRefresh] Triggered previous chapter to \(prev.number)")
        #endif
    }

    private func goToNextChapter() {
        guard let next = nextChapter else { return }
        transitionForward = true
        withAnimation(.easeInOut(duration: 0.25)) {
            currentChapterNumber = next.number
            scrollPosition = nil
        }
        #if DEBUG
        print("[MJRefresh] Triggered next chapter to \(next.number)")
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(
                        currentChapter.paragraphs,
                        id: \.startingVerse
                    ) { paragraph in
                        paragraphRow(for: paragraph)
                    }
                    // Scroll-to-end sentinel: once the last verse is visible the
                    // chapter is flagged reached-end (with ≥30s dwell → "read").
                    Color.clear
                        .frame(height: 1)
                        .onAppear { ReadingStatsService.shared.markReachedEnd() }
                }
                .id(currentChapterNumber)
                .transition(.asymmetric(
                    insertion: .move(edge: transitionForward ? .trailing : .leading),
                    removal: .move(edge: transitionForward ? .leading : .trailing)
                ))
                .animation(.easeInOut(duration: 0.25), value: currentChapterNumber)
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
        .background(readingTheme.isCustom ? readingTheme.backgroundColor(for: colorScheme) : Color.clear)
        // Removed overlay NavigationLinks; navigation happens in-place
        .scrollPosition(id: $scrollPosition, anchor: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(currentBook.name) \(currentChapter.number)")
                    .font(.headline)
            }
            if supportsVersionSwitching {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(Version.allCases, id: \.self) { version in
                            Button {
                                appViewModel.selectedVersion = version
                            } label: {
                                if version == appViewModel.selectedVersion {
                                    Label(version.displayName, systemImage: "checkmark")
                                } else {
                                    Text(version.displayName)
                                }
                            }
                        }
                    } label: {
                        Text(appViewModel.selectedVersion.shortName)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .accessibilityLabel("Bible translation: \(appViewModel.selectedVersion.displayName)")
                    .accessibilityHint("Double tap to change translation")
                    .accessibilityIdentifier("VersionPickerButton")
                }
            }
        }
        .confirmationDialog(
            "Selected Verse \(currentBook.name) \(currentChapter.number):\(selectedParagraph?.startingVerse ?? 0)",
            isPresented: $showActionSheet,
            actions: {
                Button {
                    AnalyticsService.shared.capture(.verseCopied, properties: [
                        "book": currentBook.name,
                        "chapter": currentChapter.number,
                        "verse": selectedParagraph?.startingVerse ?? 0
                    ])
                    UIPasteboard.general.string = getStringFromSelectedParagraph()
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                } label: {
                    Text("Copy")
                }
                Button {
                    guard let selectedParagraph else { return }
                    AnalyticsService.shared.capture(.verseBookmarked, properties: [
                        "book": currentBook.name,
                        "chapter": currentChapter.number,
                        "verse": selectedParagraph.startingVerse
                    ])
                    bookmarkedBookName = currentBook.name
                    bookmarkedChapterNumber = currentChapter.number
                    bookmarkedVerseNumber = selectedParagraph.startingVerse
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self.selectedParagraph = nil
                    alreadyHighlighted = nil
                    alreadyNoted = nil
                    ReviewPromptService.recordHappyMoment(requestReview: requestReview)
                } label: {
                    Text("Bookmark")
                }
                Button {
                    guard let paragraph = selectedParagraph else { return }
                    AnalyticsService.shared.capture(
                        alreadyHighlighted != nil ? .verseUnhighlighted : .verseHighlighted,
                        properties: [
                            "book": currentBook.name,
                            "chapter": currentChapter.number,
                            "verse": paragraph.startingVerse
                        ]
                    )
                    let highlightedVerse = HighlightedVerse(
                        version: currentBook.version.rawValue,
                        book: currentBook.name,
                        chapter: currentChapter.number,
                        startingVerse: paragraph.startingVerse,
                        color: highlightedColor
                    )

                    let wasAdding = alreadyHighlighted == nil
                    if let alreadyHighlightedVerse = alreadyHighlighted {
                        context.delete(alreadyHighlightedVerse)
                    } else {
                        context.insert(highlightedVerse)
                    }
                    do {
                        try context.save()
                    } catch {
                        SentryService.shared.capture(error, context: [
                            "view": "ChapterDetailView",
                            "operation": wasAdding ? "highlight_save" : "unhighlight_save",
                            "book": currentBook.name,
                            "chapter": currentChapter.number,
                            "verse": paragraph.startingVerse
                        ])
                    }
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                    if wasAdding {
                        ReviewPromptService.recordHappyMoment(requestReview: requestReview)
                    }
                } label: {
                    if alreadyHighlighted != nil {
                        Text("Unhighlight")
                    } else {
                        Text("Highlight")
                    }
                }
                Button {
                    guard selectedParagraph != nil || alreadyNoted != nil else { return }
                    AnalyticsService.shared.capture(.verseNoteOpened, properties: [
                        "book": currentBook.name,
                        "chapter": currentChapter.number,
                        "verse": selectedParagraph?.startingVerse ?? 0,
                        "has_existing_note": alreadyNoted != nil
                    ])
                    showNoteModal = true
                } label: {
                    if alreadyNoted != nil {
                        Text("View Note")
                    } else {
                        Text("Add Note")
                    }
                }
                Button {
                    guard let paragraph = selectedParagraph else { return }
                    AnalyticsService.shared.capture(.verseExplained, properties: [
                        "book": currentBook.name,
                        "chapter": currentChapter.number,
                        "verse": paragraph.startingVerse,
                        "version": currentBook.version.rawValue
                    ])
                    explanationRequest = VerseExplanationRequest(
                        bookName: currentBook.name,
                        chapter: currentChapter.number,
                        startingVerse: paragraph.startingVerse,
                        translation: currentBook.version.rawValue,
                        paragraphText: paragraph.text
                    )
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                    alreadyNoted = nil
                    ReviewPromptService.recordHappyMoment(requestReview: requestReview)
                } label: {
                    Text("Explain")
                }
                Button {
                    AnalyticsService.shared.capture(.verseShared, properties: [
                        "book": currentBook.name,
                        "chapter": currentChapter.number,
                        "verse": selectedParagraph?.startingVerse ?? 0
                    ])
                    let shareText = getStringFromSelectedParagraph()
                    let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
                    }
                    selectedParagraph = nil
                    alreadyHighlighted = nil
                    ReviewPromptService.recordHappyMoment(requestReview: requestReview)
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
            noteModalView()
        }
        .sheet(item: $explanationRequest) { request in
            VerseExplanationSheet(request: request)
        }
        // Removed left/right swipe gesture navigation in favor of pull-to-refresh style
        .onAppear {
            updateScrollPositionForContext()
            ReadingStatsService.shared.setModelContext(context)
            ReadingStatsService.shared.startReading(
                bookName: bookName,
                chapterNumber: currentChapterNumber,
                version: appViewModel.selectedVersion.rawValue
            )
            AnalyticsService.shared.capture(.chapterViewed, properties: [
                "book": currentBook.name,
                "chapter": currentChapterNumber,
                "version": appViewModel.selectedVersion.rawValue,
                "testament": "\(currentBook.testament ?? .old)"
            ])
            BadgeService.shared.checkBadges(in: context)
        }
        .onDisappear {
            ReadingStatsService.shared.stopReading()
        }
        .onChange(of: currentChapterNumber) {
            // Clear transient state when chapter changes
            selectedParagraph = nil
            alreadyHighlighted = nil
            alreadyNoted = nil
            // Jump to the top of the new chapter
            updateScrollPositionForContext()
            // Track new chapter reading session
            ReadingStatsService.shared.startReading(
                bookName: bookName,
                chapterNumber: currentChapterNumber,
                version: appViewModel.selectedVersion.rawValue
            )
            AnalyticsService.shared.capture(.chapterNavigated, properties: [
                "book": currentBook.name,
                "chapter": currentChapterNumber,
                "direction": transitionForward ? "next" : "previous",
                "version": appViewModel.selectedVersion.rawValue
            ])
        }
        .onChange(of: appViewModel.selectedVerse?.verse) {
            updateScrollPositionForContext()
        }
        #if DEBUG
        .overlay(alignment: .bottom) { ReadTrackerDebugBadge() }
        #endif
    }

    // MARK: - Helper View Methods

    @ViewBuilder
    private func paragraphRow(for paragraph: Paragraph) -> some View {
        let isHighlighted = checkIfHighlighted(paragraph: paragraph)
        let isBookmarked = checkIfBookmarked(paragraph: paragraph)
        let hasNote = checkIfNoted(paragraph: paragraph)

        Group {
            if let summary = SummariesService.shared.passageSummary(
                book: currentBook.name,
                chapter: currentChapter.number,
                startVerse: paragraph.startingVerse,
                source: summarySource
            ) {
                Text(summary)
                    .bold()
                    .padding(.top)
                    .font(Font.custom(fontName, size: CGFloat(fontSize + 1), relativeTo: .body))
            }

            HStack(alignment: .top) {
                verseNumberColumn(
                    paragraph: paragraph,
                    isBookmarked: isBookmarked,
                    hasNote: hasNote
                )

                paragraphContent(
                    paragraph: paragraph,
                    isHighlighted: isHighlighted,
                    isBookmarked: isBookmarked
                )
            }
        }
    }

    @ViewBuilder
    private func verseNumberColumn(paragraph: Paragraph, isBookmarked: Bool, hasNote: Bool) -> some View {
        VStack(alignment: .center) {
            Text("\(paragraph.startingVerse)")
                .font(.footnote)
                .foregroundColor(isBookmarked ? .accentColor : (readingTheme.isCustom ? readingTheme.secondaryTextColor(for: colorScheme) : .gray))

            if isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.footnote)
                    .foregroundColor(.accentColor)
                    .accessibilityLabel("Bookmarked verse")
            }

            if hasNote {
                Capsule()
                    .fill(Color(hex: notedColor))
                    .frame(width: 5)
                    .accessibilityLabel("Has note")
            }
        }
    }

    @ViewBuilder
    private func paragraphContent(paragraph: Paragraph, isHighlighted: Bool, isBookmarked: Bool) -> some View {
        let effectiveHighlightHex = highlightColor(for: paragraph) ?? highlightedColor
        let backgroundColor: Color = isHighlighted ? Color(hex: effectiveHighlightHex) : .clear
        let defaultTextColor: Color = readingTheme.isCustom ? readingTheme.textColor(for: colorScheme) : .primary
        let foregroundColor: Color = isHighlighted ? Color(hex: effectiveHighlightHex).accessibleFontColor : defaultTextColor

        ParagraphView(
            firstVerseNumber: paragraph.startingVerse,
            paragraph: paragraph.text,
            themeSecondaryColor: readingTheme.isCustom ? readingTheme.secondaryTextColor(for: colorScheme) : nil
        )
        .background { backgroundColor }
        .foregroundStyle(foregroundColor)
        .multilineTextAlignment(
            appViewModel.selectedVersion == .original && currentBook.testament == .old
                ? .trailing : .leading
        )
        .underline(selectedParagraph == paragraph)
        .accessibilityHint("Long press for verse actions")
        .onLongPressGesture {
            handleLongPress(paragraph: paragraph)
        }
    }

    // MARK: - Helper Methods

    private func checkIfHighlighted(paragraph: Paragraph) -> Bool {
        highlightedVerses.contains {
            $0.version == currentBook.version.rawValue &&
            $0.book == currentBook.name &&
            $0.startingVerse == paragraph.startingVerse &&
            $0.chapter == currentChapter.number
        }
    }

    private func highlightColor(for paragraph: Paragraph) -> String? {
        let match = highlightedVerses.first {
            $0.version == currentBook.version.rawValue &&
            $0.book == currentBook.name &&
            $0.startingVerse == paragraph.startingVerse &&
            $0.chapter == currentChapter.number
        }
        guard let hex = match?.color, !hex.isEmpty else { return nil }
        return hex
    }

    private func checkIfBookmarked(paragraph: Paragraph) -> Bool {
        bookmarkedBookName == currentBook.name &&
        bookmarkedChapterNumber == currentChapter.number &&
        bookmarkedVerseNumber == paragraph.startingVerse
    }

    private func checkIfNoted(paragraph: Paragraph) -> Bool {
        notes.contains {
            $0.version == currentBook.version.rawValue &&
            $0.book == currentBook.name &&
            $0.chapter == currentChapter.number &&
            $0.startingVerse == paragraph.startingVerse
        }
    }

    func handleLongPress(paragraph: Paragraph) {
        selectedParagraph = paragraph
        alreadyHighlighted = highlightedVerses.first(where: {
            $0.version == currentBook.version.rawValue &&
            $0.book == currentBook.name &&
            $0.chapter == currentChapter.number &&
            $0.startingVerse == paragraph.startingVerse
        })
        alreadyNoted = notes.first(where: {
            $0.version == currentBook.version.rawValue &&
            $0.book == currentBook.name &&
            $0.chapter == currentChapter.number &&
            $0.startingVerse == paragraph.startingVerse
        })
        showActionSheet = true
        AnalyticsService.shared.capture(.verseActionMenu, properties: [
            "book": currentBook.name,
            "chapter": currentChapter.number,
            "verse": paragraph.startingVerse,
            "version": currentBook.version.rawValue
        ])
    }

    func getStringFromSelectedParagraph() -> String {
        guard let paragraph = selectedParagraph else { return "" }
        return "\(currentBook.version.rawValue.uppercased()) Version \(currentBook.name) Chapter \(currentChapter.number) \(paragraph.startingVerse): \(paragraph.text)"
    }

    func noteModalView() -> some View {
        return NoteModalView(
            note: alreadyNoted ?? Note(
                version: currentBook.version.rawValue,
                book: currentBook.name,
                chapter: currentChapter.number,
                startingVerse: selectedParagraph?.startingVerse ?? 0,
                text: "",
                created: .now
            ),
            onSave: { note in
                context.insert(note)
                do {
                    try context.save()
                } catch {
                    SentryService.shared.capture(error, context: [
                        "view": "ChapterDetailView",
                        "operation": "note_save",
                        "book": note.book,
                        "chapter": note.chapter,
                        "verse": note.startingVerse
                    ])
                }
                selectedParagraph = nil
                alreadyHighlighted = nil
                showNoteModal = false
                ReviewPromptService.recordHappyMoment(requestReview: requestReview)
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
                    SentryService.shared.capture(error, context: [
                        "view": "ChapterDetailView",
                        "operation": "note_delete",
                        "book": note.book,
                        "chapter": note.chapter,
                        "verse": note.startingVerse
                    ])
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

        if selected.book == currentBook && selected.chapter.number == currentChapter.number {
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
