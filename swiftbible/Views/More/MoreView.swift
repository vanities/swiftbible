//
//  MoreView.swift
//  swiftbible
//
//  Hub landing for the "More" tab. A small set of distinctive cards
//  surfacing content (History), the user's library, reading stats,
//  and settings — without looking like a settings page itself.
//

import SwiftUI
import SwiftData

struct MoreView: View {
    @Binding var selectedTab: Tabs
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var appViewModel

    // Surfaced by HistoryArticleView — used to show a "Continue reading"
    // card so unfinished articles pull users back (Zeigarnik effect).
    @AppStorage("lastHistoryArticleId") private var lastHistoryArticleId: String = ""
    @AppStorage("lastHistoryArticleAt") private var lastHistoryArticleAt: Double = 0

    @AppStorage(BookmarkPreferences.bookKey) private var bookmarkedBookName: String = ""
    @AppStorage(BookmarkPreferences.chapterKey) private var bookmarkedChapterNumber: Int = 0
    @AppStorage(BookmarkPreferences.verseKey) private var bookmarkedVerseNumber: Int = 0
    @AppStorage("seenEventIDs") private var seenEventIDsRaw: String = ""

    @State private var streakDays: Int = 0
    @State private var chaptersThisWeek: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(AppEventRegistry.visibleEvents) { event in
                        eventCard(event)
                    }
                    historyHero
                    if let unfinished = unfinishedArticle {
                        continueReadingCard(article: unfinished)
                    }
                    if hasBookmark {
                        bibleBookmarkCard
                    }
                    librarySection
                    progressCard
                    statsCard
                    settingsCard
                    aboutFooter
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshStats()
                markEventsSeen()
            }
        }
    }

    /// Mark every currently-visible event as seen, clearing the More-tab badge.
    private func markEventsSeen() {
        var seen = Set(seenEventIDsRaw.split(separator: ",").map(String.init))
        let before = seen.count
        seen.formUnion(AppEventRegistry.visibleEvents.map(\.id))
        if seen.count != before {
            seenEventIDsRaw = seen.sorted().joined(separator: ",")
        }
    }

    // MARK: - Event card (date-gated, mirrors bibleBookmarkCard pattern)

    private func eventCard(_ event: AppEvent) -> some View {
        Button {
            handleEventTap(event)
        } label: {
            VStack(spacing: 0) {
                if let banner = event.bannerImageName {
                    eventBanner(image: banner, event: event)
                }
                eventCardBody(event)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(event.accent.color.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.30 : 0.06),
                    radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func eventBanner(image: String, event: AppEvent) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(image)
                .resizable()
                .aspectRatio(16.0/9.0, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()

            // Bottom gradient so the "HAPPENING NOW" pill stays legible
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 60)
            .frame(maxHeight: .infinity, alignment: .bottom)

            HStack(spacing: 6) {
                Image(systemName: event.iconName)
                    .font(.system(size: 10, weight: .semibold))
                Text("HAPPENING NOW")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(2)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule().fill(event.accent.color)
            )
            .padding(12)
        }
    }

    private func eventCardBody(_ event: AppEvent) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(event.subtitle)
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(event.accent.color)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    private func handleEventTap(_ event: AppEvent) {
        switch event.action {
        case .openVerse(let book, let chapter, let verse):
            selectedTab = .bible
            DispatchQueue.main.async {
                appViewModel.navigateToVerse(
                    bookName: book,
                    chapterNumber: chapter,
                    verseNumber: verse
                )
            }
        case .openTab(let tab):
            selectedTab = tab
        case .openEvent:
            // Present the curated EventDetailView via AppViewModel state.
            // ContentView observes presentedEvent and presents the sheet.
            appViewModel.presentedEvent = event
        }
    }

    // MARK: - Manuscript palette helpers (local to keep MoreView self-contained)

    private var parchmentInk: Color {
        colorScheme == .dark
            ? .primary                                         // iOS-native, adapts cleanly
            : Color(red: 0.18, green: 0.13, blue: 0.10)
    }

    private var parchmentMutedInk: Color {
        colorScheme == .dark
            ? .secondary                                       // iOS-native muted
            : Color(red: 0.40, green: 0.32, blue: 0.24)
    }

    private var parchmentSurface: Color {
        colorScheme == .dark
            // Match the other cards in MoreView (Highlights/Notes/Stats/Settings).
            // Lets the card sit naturally in the dark grouped list instead of
            // competing with its own theme.
            ? Color(.secondarySystemGroupedBackground)
            : Color(red: 0.965, green: 0.94, blue: 0.88)
    }

    /// Accent color for the History hero. Stays gold in both modes — gold pops
    /// on neutral dark grey (was muddy on warm brown previously).
    private var heroAccent: Color {
        Color.brandGold
    }

    // MARK: - History hero

    private var historyHero: some View {
        NavigationLink(destination: HistoryView()) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Rectangle()
                        .frame(width: 16, height: 1)
                        .foregroundStyle(heroAccent.opacity(0.85))
                    Text("LEARN")
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .tracking(2.5)
                        .foregroundStyle(heroAccent)
                    Rectangle()
                        .frame(width: 16, height: 1)
                        .foregroundStyle(heroAccent.opacity(0.85))
                    Spacer()
                    Image(systemName: "scroll.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(heroAccent.opacity(0.9))
                }

                Text("History of the\nChristian Church")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(parchmentInk)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Two thousand years — from the patriarchs to today, in 29 articles.")
                    .font(.system(size: 14, design: .serif))
                    .italic()
                    .foregroundStyle(parchmentMutedInk)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .overlay(heroAccent.opacity(0.32))
                    .padding(.top, 4)

                HStack {
                    Text("9 SECTIONS · 29 ARTICLES")
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(parchmentMutedInk)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(heroAccent)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(heroBackground)
        }
        .buttonStyle(.plain)
    }

    private var heroBackground: some View {
        ZStack {
            parchmentSurface
            // Light mode keeps the warm parchment glow; dark mode stays clean
            // (no gradients) to match the other cards in MoreView.
            if colorScheme == .light {
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.93, blue: 0.72).opacity(0.55), .clear],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 320
                )
                .blendMode(.multiply)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            // Subtle gold border in both modes — single accent that ties the
            // card to its "ancient text" identity without overwhelming.
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.brandGold.opacity(colorScheme == .dark ? 0.40 : 0.30),
                              lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.30 : 0.06),
                radius: 8, x: 0, y: 3)
    }

    // MARK: - Continue reading card (Zeigarnik open-loop)

    private var unfinishedArticle: HistoryArticle? {
        guard !lastHistoryArticleId.isEmpty else { return nil }
        let last = Date(timeIntervalSince1970: lastHistoryArticleAt)
        guard Date().timeIntervalSince(last) < 7 * 24 * 3600 else { return nil }
        return HistoryContent.article(id: lastHistoryArticleId)
    }

    private func continueReadingCard(article: HistoryArticle) -> some View {
        NavigationLink(destination: HistoryArticleView(article: article)) {
            HStack(spacing: 12) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.brandGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CONTINUE READING")
                        .font(.system(size: 9, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(Color.brandGold)
                    Text(article.title)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.brandGold)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.brandGold)
                            .frame(width: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bible bookmark card

    private var hasBookmark: Bool {
        !bookmarkedBookName.isEmpty && bookmarkedChapterNumber > 0
    }

    private var bookmarkSummary: String {
        guard hasBookmark else { return "" }
        if bookmarkedVerseNumber > 0 {
            return "\(bookmarkedBookName) \(bookmarkedChapterNumber):\(bookmarkedVerseNumber)"
        }
        return "\(bookmarkedBookName) \(bookmarkedChapterNumber)"
    }

    private var bibleBookmarkCard: some View {
        Button {
            let book = bookmarkedBookName
            let chapter = bookmarkedChapterNumber
            let verse = bookmarkedVerseNumber
            selectedTab = .bible
            DispatchQueue.main.async {
                appViewModel.navigateToVerse(
                    bookName: book,
                    chapterNumber: chapter,
                    verseNumber: verse
                )
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.brandRedDark)

                VStack(alignment: .leading, spacing: 2) {
                    Text("BIBLE BOOKMARK")
                        .font(.system(size: 9, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(Color.brandRedDark)
                    Text(bookmarkSummary)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.brandRedDark)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.brandRedDark)
                            .frame(width: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Library row (Notes in centre — Centre-Stage Effect)

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR LIBRARY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
                .padding(.top, 2)

            HStack(spacing: 10) {
                libraryCard(
                    title: "Highlights",
                    icon: "highlighter",
                    tint: .brandGold,
                    destination: AnyView(SeeHighlightsView(selectedTab: $selectedTab))
                )
                libraryCard(
                    title: "Notes",
                    icon: "note.text",
                    tint: .brandAccent,
                    destination: AnyView(SeeSavedNotesView(selectedTab: $selectedTab))
                )
                libraryCard(
                    title: "Devotionals",
                    icon: "heart.circle.fill",
                    tint: .brandRed,
                    destination: AnyView(SavedDevotionalsListView())
                )
            }
        }
    }

    private func libraryCard(
        title: String,
        icon: String,
        tint: Color,
        destination: AnyView
    ) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Progress card (streak + heatmap + 66-book grid)

    private var progressCard: some View {
        NavigationLink(destination: ProgressTabView()) {
            cardRow(
                icon: "flame.fill",
                tint: .orange,
                title: "Progress",
                subtitle: progressSubtitle
            )
        }
        .buttonStyle(.plain)
    }

    private var progressSubtitle: String {
        if streakDays == 0 {
            return "Streak, heatmap, and book completion"
        }
        return "\u{1F525} \(streakDays)-day streak · books read"
    }

    // MARK: - Reading stats card (live numbers — Endowed Progress)

    private var statsCard: some View {
        NavigationLink(destination: ReadingStatsView()) {
            cardRow(
                icon: "chart.bar.fill",
                tint: .brandGreen,
                title: "Reading Stats",
                subtitle: statsSubtitle
            )
        }
        .buttonStyle(.plain)
    }

    private var statsSubtitle: String {
        if streakDays == 0 && chaptersThisWeek == 0 {
            return "Streaks, verses, and time spent reading"
        }
        var parts: [String] = []
        if streakDays > 0 {
            parts.append("\u{1F525} \(streakDays)-day streak")
        }
        if chaptersThisWeek > 0 {
            parts.append("\(chaptersThisWeek) chapter\(chaptersThisWeek == 1 ? "" : "s") this week")
        }
        return parts.joined(separator: " · ")
    }

    private func refreshStats() {
        Task { @MainActor in
            streakDays = ReadingStatsService.shared.currentStreak(in: modelContext)
            let weekly = ReadingStatsService.shared.sessionsThisWeek(in: modelContext)
            let unique = Set(weekly.map { "\($0.bookName)-\($0.chapterNumber)" })
            chaptersThisWeek = unique.count
        }
    }

    // MARK: - Settings card

    private var settingsCard: some View {
        NavigationLink(destination: SettingsView(selectedTab: $selectedTab)) {
            cardRow(
                icon: "gearshape.fill",
                tint: .brandAccent,
                title: "Settings",
                subtitle: "Translations, fonts, notifications, and more"
            )
        }
        .buttonStyle(.plain)
    }

    private func cardRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - About footer

    private var aboutFooter: some View {
        VStack(spacing: 4) {
            Text("swiftbible")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(.secondary)
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                Text("v\(version)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
    }
}
