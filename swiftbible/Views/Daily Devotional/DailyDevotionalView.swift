//
//  DailyDevotionalView.swift
//  swiftbible
//
//  Created on 9/6/24.
//

import SwiftUI
import SwiftData
import StoreKit
import MarkdownUI

struct DailyDevotionalView: View {
    @AppStorage("fontSize") private var fontSize: Int = 20
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) private var requestReview

    @Binding var selectedTab: Tabs

    @State private var message: String = ""
    @State private var isLoading: Bool = false
    @State private var hasDevotional: Bool = false
    @State private var selectedDate: Date = Date()
    @State var calendarId: UUID = UUID()
    @State private var showToast = false
    @State private var savedDevotional: SavedDevotional?
    @State private var isFavorite = false

    // Animations
    @State private var pulse = false
    @State private var showNoDevotional = false
    @State private var sparkleTwinkle = false
    @State private var heartBounce = false
    @State private var devotionalType: String = "single"
    @State private var showCustomDisclosure = false
    @State private var showHolidayDisclosure = false
    @State private var seriesName: String?
    @State private var seriesPart: Int?
    @State private var holidayName: String?
    @State private var holidayUrl: String?
    @State private var anchorVerse: String?
    @State private var verses: [DevotionalVerse]?
    @State private var model: String?
    @State private var track: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .id(calendarId)
                    .onChange(of: selectedDate) {
                        Task { await fetchDailyDevotional(for: selectedDate) }
                        calendarId = UUID()
                    }

                Button {
                    goToToday()
                } label: {
                    Label("Today", systemImage: "clock.arrow.circlepath")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(Calendar.current.isDateInToday(selectedDate))
                .accessibilityLabel("Go to today's devotional")

                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .pink : .secondary)
                        .font(.title3)
                        .symbolEffect(.bounce, value: isFavorite)
                        .scaleEffect(heartBounce ? 1.3 : 1.0)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!hasDevotional)
                .accessibilityLabel(isFavorite ? "Remove from saved devotionals" : "Save devotional")

                Spacer()

                devotionalBadge
            }
            .padding(.horizontal)
            .padding(.top)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            if hasDevotional {
                themeContextRow
            }

            if isLoading {
                VStack(spacing: 12) {
                    Spacer()

                    Image(systemName: "book.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)
                        .scaleEffect(pulse ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }

                    Text(fetchingMessageText(for: selectedDate))
                        .transition(.opacity)

                    Spacer()
                }
                .padding(.top, 40)
            } else if hasDevotional {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Markdown(addVerseLinks(to: message))
                            .markdownBlockStyle(\.heading1) { configuration in
                                configuration.label
                                    .markdownMargin(top: .em(1), bottom: .em(1))
                                    .markdownTextStyle {
                                        FontWeight(.bold)
                                        FontSize(.em(1))
                                    }
                            }
                            .environment(\.openURL, OpenURLAction { url in
                                guard url.scheme == "swiftbible",
                                      url.host == "verse",
                                      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                                      let book = components.queryItems?.first(where: { $0.name == "book" })?.value,
                                      let chapterStr = components.queryItems?.first(where: { $0.name == "chapter" })?.value,
                                      let verseStr = components.queryItems?.first(where: { $0.name == "verse" })?.value,
                                      let chapter = Int(chapterStr),
                                      let verse = Int(verseStr)
                                else { return .systemAction }

                                selectedTab = .bible
                                appViewModel.navigateToVerse(
                                    bookName: book,
                                    chapterNumber: chapter,
                                    verseNumber: verse
                                )
                                return .handled
                            })
                    }
                    .padding()
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)
                    .contextMenu {
                        Button(action: {
                            AnalyticsService.shared.capture(.devotionalCopied, properties: devotionalAnalyticsProperties())
                            UIPasteboard.general.string = markdownToPlainText(message)
                            withAnimation {
                                showToast = true
                            }
                            // Auto-dismiss after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showToast = false
                                }
                            }
                        }) {
                            Label("Copy Devotional", systemImage: "doc.on.doc")
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()

                    Image(systemName: "sparkles")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(sparkleTwinkle ? -2 : 2))
                        .opacity(sparkleTwinkle ? 0.9 : 1.0)
                        .scaleEffect(showNoDevotional ? 1 : 0.8)
                        .foregroundColor(.accentColor)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: sparkleTwinkle)
                        .onAppear {
                            sparkleTwinkle = true
                            showNoDevotional = true
                        }
                        .onDisappear {
                            sparkleTwinkle = false
                            showNoDevotional = false
                        }

                    Text("No devotional found for this day.")
                        .opacity(showNoDevotional ? 1 : 0)
                        .animation(.easeIn.delay(0.2), value: showNoDevotional)

                    Text(selectedDate > Date()
                         ? "Come back on \(formattedDate(selectedDate))!"
                         : "We may have missed this one.")
                    .foregroundColor(.secondary)
                    .opacity(showNoDevotional ? 1 : 0)
                    .animation(.easeIn.delay(0.3), value: showNoDevotional)

                    Spacer()
                }
                .padding(.top, 40)
                .onAppear {
                    showNoDevotional = true
                }
            }
        }
        .overlay(
            Group {
                if showToast {
                    Text("Copied to clipboard")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 40)
                }
            },
            alignment: .top
        )
        .font(Font.custom(fontName, size: CGFloat(fontSize), relativeTo: .body))
        .onAppear {
            // Clean expired cache on view appearance
            CacheService.shared.cleanExpiredCache()
            Task { await fetchDailyDevotional(for: selectedDate) }
        }
        .onDisappear {
            selectedDate = Date()
        }
        .accessibilityIdentifier("DailyDevotionalView")
    }

    @ViewBuilder
    private var devotionalBadge: some View {
        if devotionalType == "custom" {
            customBadge
        } else if let holidayName, !holidayName.isEmpty {
            holidayBadge(name: holidayName)
        } else if devotionalType == "multi" {
            AIGeneratedBadge(
                message: AIAttribution.devotionalDual(model: model),
                symbolName: "sparkles",
                primaryTint: .cyan,
                secondaryTint: .blue
            )
        } else {
            AIGeneratedBadge(
                message: AIAttribution.devotionalSingle(model: model),
                symbolName: "sparkle",
                primaryTint: .yellow,
                secondaryTint: .orange
            )
        }
    }

    private var customBadge: some View {
        Button { showCustomDisclosure = true } label: {
            AnimatedBadgeCircle(
                symbolName: "pencil.and.scribble",
                primaryTint: .brandGold,
                secondaryTint: .brandGoldLight,
                tertiaryTint: .brandPeridot
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Custom devotional. Tap to learn more.")
        .alert("Hand-crafted devotional", isPresented: $showCustomDisclosure) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This devotional was personally written by Adam, the developer of SwiftBible, rather than generated by AI.")
        }
    }

    private func holidayBadge(name: String) -> some View {
        let palette = HolidayBadgePalette.palette(for: name)
        return Button { showHolidayDisclosure = true } label: {
            AnimatedBadgeCircle(
                symbolName: palette.symbol,
                primaryTint: palette.primary,
                secondaryTint: palette.secondary,
                tertiaryTint: palette.tertiary
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Holiday devotional for \(name). Tap to learn more.")
        .alert(name, isPresented: $showHolidayDisclosure) {
            if let holidayUrl, let url = URL(string: holidayUrl) {
                Button("Read on Wikipedia") { UIApplication.shared.open(url) }
            }
            Button("Close", role: .cancel) {}
        } message: {
            Text(AIAttribution.devotionalHoliday(name: name, model: model))
        }
    }

    private func devotionalAnalyticsProperties(extra: [String: Any] = [:]) -> [String: Any] {
        var properties: [String: Any] = ["devotional_type": devotionalType]
        if let track { properties["track"] = track }
        if let seriesName { properties["series_name"] = seriesName }
        if let holidayName { properties["holiday_name"] = holidayName }
        if let model { properties["model"] = model }
        for (key, value) in extra {
            properties[key] = value
        }
        return properties
    }

    @MainActor
    private func applyDevotional(_ devotional: DailyDevotional) {
        message = devotional.message
        devotionalType = devotional.devotional_type ?? "single"
        seriesName = devotional.series_name
        seriesPart = devotional.series_part
        holidayName = devotional.holiday_name
        holidayUrl = devotional.holiday_url
        anchorVerse = devotional.anchor_verse
        verses = devotional.verses
        model = devotional.model
        track = devotional.track
        hasDevotional = true

        // Today's devotional opens count toward the daily reading streak.
        // Past-date browsing (selectedDate < today) is excluded so people can
        // catch up without retroactively patching old days.
        if Calendar.current.isDateInToday(selectedDate) {
            ReadingStatsService.shared.logDevotionalRead(for: Date(), in: context)
        }
    }

    @ViewBuilder
    private var themeContextRow: some View {
        let chipTrack: String? = {
            switch track {
            case "empathy", "technical", "narrative", "practical": return track
            default: return nil
            }
        }()
        if chipTrack != nil || hasThemeContext {
            HStack(spacing: 8) {
                if let chipTrack {
                    DevotionalStyleChip(track: chipTrack)
                }
                themeContextLabel
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 6)
        }
    }

    private var hasThemeContext: Bool {
        if holidayName != nil { return true }
        if seriesName != nil && seriesPart != nil { return true }
        if let anchorVerse, devotionalType == "single",
           parseVerseReference(anchorVerse) != nil { return true }
        if devotionalType == "multi", let verses, !verses.isEmpty { return true }
        return false
    }

    @ViewBuilder
    private var themeContextLabel: some View {
        if let holidayName {
            themeContextLabelContent(
                icon: "sparkles",
                text: "Created for \(holidayName)",
                showsExternalLink: holidayUrl != nil
            )
            .onTapGesture {
                guard let url = holidayUrl.flatMap(URL.init(string:)) else { return }
                UIApplication.shared.open(url)
            }
        } else if let seriesName, let seriesPart {
            themeContextLabelContent(
                icon: "books.vertical",
                text: "\(seriesName) · Week \(seriesPart)",
                showsExternalLink: false
            )
        } else if let anchorVerse, devotionalType == "single",
                  let parsed = parseVerseReference(anchorVerse) {
            themeContextLabelContent(
                icon: "text.book.closed",
                text: "Inspired by \(anchorVerse)",
                showsExternalLink: false
            )
            .onTapGesture {
                selectedTab = .bible
                appViewModel.navigateToVerse(
                    bookName: parsed.book,
                    chapterNumber: parsed.chapter,
                    verseNumber: parsed.verse
                )
            }
        } else if devotionalType == "multi", let verses, !verses.isEmpty {
            themeContextLabelContent(
                icon: "books.vertical",
                text: "Inspired by \(uniqueBooks(in: verses).formatted(.list(type: .and, width: .standard)))",
                showsExternalLink: false
            )
        }
    }

    private func uniqueBooks(in verses: [DevotionalVerse]) -> [String] {
        var seen = Set<String>()
        return verses.compactMap { seen.insert($0.book).inserted ? $0.book : nil }
    }

    private func themeContextLabelContent(icon: String, text: String, showsExternalLink: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .lineLimit(2)
            if showsExternalLink {
                Image(systemName: "arrow.up.forward.square")
                    .font(.caption2)
            }
        }
        .foregroundStyle(.secondary)
    }

    private func parseVerseReference(_ ref: String) -> (book: String, chapter: Int, verse: Int)? {
        let pattern = #"^(.+?)\s+(\d+):(\d+)(?:[-\d]+)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: ref, range: NSRange(ref.startIndex..., in: ref)),
              let bookRange = Range(match.range(at: 1), in: ref),
              let chapterRange = Range(match.range(at: 2), in: ref),
              let verseRange = Range(match.range(at: 3), in: ref),
              let chapter = Int(ref[chapterRange]),
              let verse = Int(ref[verseRange])
        else { return nil }
        return (book: String(ref[bookRange]).trimmingCharacters(in: .whitespaces), chapter: chapter, verse: verse)
    }

    @MainActor
    private func fetchDailyDevotional(for date: Date) async {
        isLoading = true
        hasDevotional = false
        showNoDevotional = false
        message = ""
        savedDevotional = nil
        isFavorite = false
        devotionalType = "single"
        seriesName = nil
        seriesPart = nil
        holidayName = nil
        holidayUrl = nil
        anchorVerse = nil
        track = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        // Check cache first
        if let cachedDevotional = CacheService.shared.loadDevotional(for: date) {
            applyDevotional(cachedDevotional)
            AnalyticsService.shared.capture(
                .devotionalViewed,
                properties: devotionalAnalyticsProperties(extra: [
                    "date": dateString,
                    "source": "cache"
                ])
            )
            updateSavedState(for: date)
            isLoading = false
            return
        }

        // Cache miss - fetch from Supabase
        do {
            let devotional: DailyDevotional = try await SupabaseService.shared.client
                .from("Daily Devotional")
                .select()
                .eq("for_date", value: dateString)
                .single()
                .execute()
                .value

            applyDevotional(devotional)

            AnalyticsService.shared.capture(
                .devotionalViewed,
                properties: devotionalAnalyticsProperties(extra: [
                    "date": dateString,
                    "source": "network"
                ])
            )

            // Save to cache
            CacheService.shared.saveDevotional(devotional, for: date)
            updateSavedState(for: date)
        } catch {
            print("No devotional found for \(dateString): \(error)")
            updateSavedState(for: date)
        }

        isLoading = false
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .long
        return df.string(from: date)
    }

    private func fetchingMessageText(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Fetching today's message..."
        } else if calendar.isDateInYesterday(date) {
            return "Fetching yesterday's message..."
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            let day = calendar.component(.day, from: date)
            let suffix = daySuffix(day)
            return "Fetching \(formatter.string(from: date))\(suffix)'s message..."
        }
    }

    private func daySuffix(_ day: Int) -> String {
        switch day {
        case 11, 12, 13: return "th"
        default:
            switch day % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }

    @MainActor
    private func goToToday() {
        selectedDate = Date()
        calendarId = UUID()
        Task { await fetchDailyDevotional(for: selectedDate) }
    }

    @MainActor
    private func toggleFavorite() {
        guard hasDevotional else { return }

        if let savedDevotional {
            context.delete(savedDevotional)
            try? context.save()
            AnalyticsService.shared.capture(.devotionalUnsaved, properties: devotionalAnalyticsProperties())
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2)) {
                heartBounce = true
                isFavorite = false
            }
        } else {
            let devotional = SavedDevotional(date: selectedDate, message: message)
            context.insert(devotional)
            try? context.save()
            AnalyticsService.shared.capture(.devotionalSaved, properties: devotionalAnalyticsProperties())
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2)) {
                heartBounce = true
                isFavorite = true
            }
            savedDevotional = devotional

            ReviewPromptService.recordHappyMoment(requestReview: requestReview)
        }

        updateSavedState(for: selectedDate)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                heartBounce = false
            }
        }
    }

    @MainActor
    private func updateSavedState(for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let descriptor = FetchDescriptor<SavedDevotional>(
            predicate: #Predicate { devotional in
                devotional.date >= startOfDay && devotional.date < endOfDay
            }
        )

        if let match = try? context.fetch(descriptor).first {
            savedDevotional = match
            isFavorite = true
        } else {
            savedDevotional = nil
            isFavorite = false
        }
    }

    private static let bookNames: [String] = [
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
        "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
        "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles",
        "Ezra", "Nehemiah", "Esther", "Job", "Psalms", "Psalm", "Proverbs",
        "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah",
        "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
        "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah",
        "Haggai", "Zechariah", "Malachi",
        "Matthew", "Mark", "Luke", "John", "Acts", "Romans",
        "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
        "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
        "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews",
        "James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John",
        "Jude", "Revelation"
    ].sorted { $0.count > $1.count }

    private func findVerseURL(in text: String) -> String? {
        for bookName in Self.bookNames {
            let escaped = NSRegularExpression.escapedPattern(for: bookName)
            let pattern = escaped + #"\s+(\d+):(\d+)"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               let chapterRange = Range(match.range(at: 1), in: text),
               let verseRange = Range(match.range(at: 2), in: text),
               let chapter = Int(text[chapterRange]),
               let verse = Int(text[verseRange]) {
                let normalizedName = bookName == "Psalm" ? "Psalms" : bookName
                let encodedBook = normalizedName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? normalizedName
                return "swiftbible://verse?book=\(encodedBook)&chapter=\(chapter)&verse=\(verse)"
            }
        }
        return nil
    }

    private func addVerseLinks(to text: String) -> String {
        let lines = text.components(separatedBy: "\n")

        // Pre-scan: find all verse reference URLs and their line positions
        // in blockquotes (e.g., "> **Psalms 23:1**" on line 4)
        var blockquoteVerseRefs: [(lineIndex: Int, url: String)] = []
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(">"), let url = findVerseURL(in: trimmed) {
                blockquoteVerseRefs.append((lineIndex: i, url: url))
            }
        }

        return lines.enumerated().map { (i, line) in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Don't link headings
            if trimmed.hasPrefix("#") { return line }

            // For blockquote lines, find the nearest verse reference
            // by looking forward first (reference comes after quote text),
            // then backward for lines after the last reference
            if trimmed.hasPrefix(">") {
                let url: String? = {
                    // Look forward to next reference
                    if let fwd = blockquoteVerseRefs.first(where: { $0.lineIndex >= i }) {
                        return fwd.url
                    }
                    // Look backward to previous reference
                    if let bwd = blockquoteVerseRefs.last(where: { $0.lineIndex <= i }) {
                        return bwd.url
                    }
                    // Fallback: first verse in entire text
                    return findVerseURL(in: text)
                }()

                guard let url else { return line }
                let content = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                guard !content.isEmpty else { return line }
                let safe = content
                    .replacingOccurrences(of: "[", with: "\\[")
                    .replacingOccurrences(of: "]", with: "\\]")
                return "> [\(safe)](\(url))"
            }

            // Link verse references in regular text
            return linkVerseRefsInLine(line)
        }.joined(separator: "\n")
    }

    private func linkVerseRefsInLine(_ line: String) -> String {
        var result = line
        for bookName in Self.bookNames {
            let escaped = NSRegularExpression.escapedPattern(for: bookName)
            let pattern = #"(?<!\[)"# + escaped + #"\s+(\d+):(\d+)(?:-\d+)?(?!\])"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            guard !matches.isEmpty else { continue }

            let mutableResult = NSMutableString(string: result)
            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: result),
                      let chapterRange = Range(match.range(at: 1), in: result),
                      let verseRange = Range(match.range(at: 2), in: result),
                      let chapter = Int(result[chapterRange]),
                      let verse = Int(result[verseRange]) else { continue }

                let displayText = String(result[fullRange])
                let normalizedName = bookName == "Psalm" ? "Psalms" : bookName
                let encodedBook = normalizedName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? normalizedName
                let link = "[\(displayText)](swiftbible://verse?book=\(encodedBook)&chapter=\(chapter)&verse=\(verse))"
                mutableResult.replaceCharacters(in: match.range, with: link)
            }
            result = mutableResult as String
        }
        return result
    }
}

#Preview {
    DailyDevotionalView(selectedTab: .constant(.dailyDevotional))
        .environment(UserViewModel())
        .environment(AppViewModel())
}
