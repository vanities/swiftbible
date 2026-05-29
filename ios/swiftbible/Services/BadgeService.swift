//
//  BadgeService.swift
//  swiftbible
//

import Foundation
import SwiftData

@MainActor
final class BadgeService {
    static let shared = BadgeService()

    private init() {}

    // MARK: - Public API

    /// Evaluates every badge condition and inserts new EarnedBadge rows for
    /// any that newly qualify. Called from chapter/devotional/scene-active
    /// hooks. Returns the list of newly-earned definitions so callers can
    /// optionally trigger a toast immediately.
    @discardableResult
    func checkBadges(in context: ModelContext, triggerDate: Date = Date()) -> [BadgeDefinition] {
        let earnedIds = currentEarnedIds(in: context)
        var newlyEarned: [BadgeDefinition] = []

        for definition in BadgeRegistry.all {
            guard !earnedIds.contains(definition.id) else { continue }
            guard evaluate(definition, in: context, on: triggerDate) else { continue }

            // notified=true because we immediately enqueue a live toast
            // via ToastService; the Progress-tab "missed notifications"
            // path is only a fallback for badges earned before the
            // ToastService observer is mounted (rare on cold launch).
            let badge = EarnedBadge(badgeId: definition.id, earnedAt: Date(), notified: true)
            context.insert(badge)
            newlyEarned.append(definition)

            ToastService.shared.enqueue(definition)

            AnalyticsService.shared.capture(.badgeEarned, properties: [
                "badge_id": definition.id,
                "category": definition.category.rawValue,
                "name": definition.name
            ])
        }

        if !newlyEarned.isEmpty {
            try? context.save()
        }
        return newlyEarned
    }

    func earnedDefinitions(in context: ModelContext) -> [BadgeDefinition] {
        let ids = currentEarnedIds(in: context)
        return BadgeRegistry.all.filter { ids.contains($0.id) }
    }

    func isEarned(_ definition: BadgeDefinition, in context: ModelContext) -> Bool {
        currentEarnedIds(in: context).contains(definition.id)
    }

    /// Highest unlocked tier per track, or nil if the user has none yet.
    func currentTier(track: BadgeTrack, in context: ModelContext) -> BadgeTier? {
        let earned = earnedDefinitions(in: context)
            .filter { $0.track == track }
            .compactMap { $0.tier }
        return earned.max()
    }

    /// Returns unnotified earned badges and marks them notified after read.
    /// The toast layer calls this to find what to celebrate this session.
    func consumePendingNotifications(in context: ModelContext) -> [BadgeDefinition] {
        let descriptor = FetchDescriptor<EarnedBadge>(
            predicate: #Predicate { !$0.notified }
        )
        guard let pending = try? context.fetch(descriptor), !pending.isEmpty else { return [] }
        let definitions = pending.compactMap { BadgeRegistry.definition(forId: $0.badgeId) }
        for badge in pending {
            badge.notified = true
        }
        try? context.save()
        return definitions
    }

    // MARK: - Private helpers

    private func currentEarnedIds(in context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<EarnedBadge>()
        let rows = (try? context.fetch(descriptor)) ?? []
        return Set(rows.map { $0.badgeId })
    }

    // MARK: - Evaluation dispatch

    private func evaluate(_ definition: BadgeDefinition, in context: ModelContext, on date: Date) -> Bool {
        switch definition.category {
        case .tier:
            return evaluateTier(definition, in: context)
        case .collectible:
            return evaluateCollectible(definition, in: context)
        case .hidden:
            return evaluateHidden(definition, in: context, on: date)
        }
    }

    private func evaluateTier(_ definition: BadgeDefinition, in context: ModelContext) -> Bool {
        guard let track = definition.track, let threshold = definition.threshold else { return false }
        let stats = ReadingStatsService.shared
        switch track {
        case .streak:
            return stats.currentStreakWithFreeze(in: context).streak >= threshold
        case .chapters:
            return stats.totalChaptersRead(in: context) >= threshold
        case .books:
            return completedBookCount(in: context) >= threshold
        case .devotionals:
            return devotionalReadCount(in: context) >= threshold
        case .time:
            return Int(stats.totalReadingTime(in: context) / 3600) >= threshold
        case .versions:
            return stats.chaptersReadInAllVersions(in: context) >= threshold
        case .scribe:
            return annotationCount(in: context) >= threshold
        }
    }

    private func evaluateCollectible(_ definition: BadgeDefinition, in context: ModelContext) -> Bool {
        let stats = ReadingStatsService.shared
        switch definition.id {
        case "collect.gospels":
            return allComplete(["Matthew", "Mark", "Luke", "John"], in: context, stats: stats)
        case "collect.pentateuch":
            return allComplete(["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy"], in: context, stats: stats)
        case "collect.major.prophets":
            return allComplete(["Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel"], in: context, stats: stats)
        case "collect.minor.prophets":
            let books = ["Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah",
                         "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi"]
            return allComplete(books, in: context, stats: stats)
        case "collect.pauline":
            let books = ["Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
                         "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
                         "1 Timothy", "2 Timothy", "Titus", "Philemon"]
            return allComplete(books, in: context, stats: stats)
        case "collect.wisdom":
            return allComplete(["Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon"], in: context, stats: stats)
        case "collect.enoch":
            let books = ["The Book of the Watchers", "The Book of Parables",
                         "The Astronomical Book", "The Book of Dream Visions",
                         "The Epistle of Enoch"]
            // Enoch books need any chapter read in each section (we don't have
            // canonical chapter counts hardcoded for these), so check for ≥1.
            return books.allSatisfy { stats.chaptersReadInBook($0, in: context).isEmpty == false }
        case "collect.apocrypha":
            // Same approach — ≥1 chapter read in each apocryphal book.
            return Testament.apocryphaNames.allSatisfy { stats.chaptersReadInBook($0, in: context).isEmpty == false }
        case "collect.whole.counsel":
            return completedBookCount(in: context) >= 66
        case "collect.ot":
            return allComplete(CanonicalBibleBooks.oldTestament.map { $0.name }, in: context, stats: stats)
        case "collect.nt":
            return allComplete(CanonicalBibleBooks.newTestament.map { $0.name }, in: context, stats: stats)
        case "collect.synoptics":
            return allComplete(["Matthew", "Mark", "Luke"], in: context, stats: stats)
        case "collect.general.epistles":
            let books = ["James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude"]
            return allComplete(books, in: context, stats: stats)
        case "collect.luke.acts":
            return allComplete(["Luke", "Acts"], in: context, stats: stats)
        case "collect.historical":
            let books = ["Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings",
                         "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah", "Esther"]
            return allComplete(books, in: context, stats: stats)
        case "collect.solomon":
            return allComplete(["Proverbs", "Ecclesiastes", "Song of Solomon"], in: context, stats: stats)
        case "collect.megillot":
            return allComplete(["Ruth", "Esther", "Ecclesiastes", "Song of Solomon", "Lamentations"],
                               in: context, stats: stats)
        case "collect.event.pentecost":
            return Self.isEventPlanComplete(idPrefix: "pentecost-")
        case "collect.event.summer.psalms":
            return Self.isEventPlanComplete(idPrefix: "summer-psalms-")
        default:
            return false
        }
    }

    // MARK: - Seasonal event reading plans

    /// Completed event reading-day IDs. Mirrors the `seenEventIDs` AppStorage
    /// format (comma-separated); EventDetailView appends a day's id once the
    /// user views it unlocked.
    static func completedEventDayIDs() -> Set<String> {
        let raw = UserDefaults.standard.string(forKey: "completedEventDayIDs") ?? ""
        return Set(raw.split(separator: ",").map(String.init))
    }

    /// True when any event whose id starts with `idPrefix` has every day of
    /// its reading plan completed. The prefix lets a yearly event reuse one
    /// badge (pentecost-2026, pentecost-2027, …).
    static func isEventPlanComplete(idPrefix: String) -> Bool {
        let completed = completedEventDayIDs()
        let events = AppEventRegistry.allEvents.filter { $0.id.hasPrefix(idPrefix) && !$0.readingPlan.isEmpty }
        guard !events.isEmpty else { return false }
        return events.contains { event in
            event.readingPlan.allSatisfy { completed.contains($0.id) }
        }
    }

    private func evaluateHidden(_ definition: BadgeDefinition, in context: ModelContext, on date: Date) -> Bool {
        let stats = ReadingStatsService.shared
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        switch definition.id {
        case "hidden.night.owl":
            // 00:00–02:59 with at least one chapter read today
            guard hour >= 0 && hour < 3 else { return false }
            return chaptersReadOn(date, in: context) > 0
        case "hidden.early.bird":
            // 04:00–05:59
            guard hour >= 4 && hour < 6 else { return false }
            return chaptersReadOn(date, in: context) > 0
        case "hidden.marathon":
            return chaptersReadOn(date, in: context) >= 10
        case "hidden.pentecost":
            return LiturgicalCalendar.isPentecost(date) &&
                   readChapter(book: "Acts", chapter: 2, on: date, in: context)
        case "hidden.resurrection.sunday":
            return LiturgicalCalendar.isEaster(date) && chaptersReadOn(date, in: context) > 0
        case "hidden.christmas.story":
            return LiturgicalCalendar.isChristmas(date) &&
                   readChapter(book: "Luke", chapter: 2, on: date, in: context)
        case "hidden.all.voices":
            let tracks = DevotionalHistory.tracksInLast(days: 7)
            return ["empathy", "technical", "narrative", "practical"].allSatisfy { tracks.contains($0) }
        case "hidden.series.completionist":
            // Any series where the user has viewed parts 1, 2, 3, and 4
            let progress = DevotionalHistory.seriesProgress()
            return progress.values.contains { $0.isSuperset(of: [1, 2, 3, 4]) }
        case "hidden.phoenix":
            let info = stats.currentStreakWithFreeze(in: context)
            return info.freezeActive && info.streak > 0
        case "hidden.late.wisdom":
            guard hour >= 22 else { return false }
            return readChapterToday(book: "Proverbs", in: context)
        case "hidden.alpha.omega":
            return stats.chaptersReadInBook("Genesis", in: context).contains(1)
                && stats.chaptersReadInBook("Revelation", in: context).contains(22)
        case "hidden.in.the.beginning":
            return stats.chaptersReadInBook("Genesis", in: context).contains(1)
                && stats.chaptersReadInBook("John", in: context).contains(1)
        case "hidden.forty.days":
            return stats.currentStreakWithFreeze(in: context).streak >= 40
        case "hidden.jubilee":
            return stats.currentStreakWithFreeze(in: context).streak >= 50
        case "hidden.sermon.mount":
            return readChapter(book: "Matthew", chapter: 5, on: date, in: context)
                && readChapter(book: "Matthew", chapter: 6, on: date, in: context)
                && readChapter(book: "Matthew", chapter: 7, on: date, in: context)
        case "hidden.longest.mile":
            return stats.chaptersReadInBook("Psalms", in: context).contains(119)
        case "hidden.hall.of.faith":
            return stats.chaptersReadInBook("Hebrews", in: context).contains(11)
        case "hidden.watchnight":
            return LiturgicalCalendar.isWatchnight(date) && chaptersReadOn(date, in: context) > 0
        case "hidden.good.friday":
            return LiturgicalCalendar.isGoodFriday(date) && chaptersReadOn(date, in: context) > 0
        case "hidden.ash.wednesday":
            return LiturgicalCalendar.isAshWednesday(date) && chaptersReadOn(date, in: context) > 0
        case "hidden.advent":
            let year = calendar.component(.year, from: date)
            let sundays = LiturgicalCalendar.adventSundays(year: year)
            return sundays.count == 4 && sundays.allSatisfy { hasAnySessionOn($0, in: context) }
        case "hidden.watchers":
            return stats.chaptersReadInBook("The Book of the Watchers", in: context).count >= 36
        default:
            return false
        }
    }

    // MARK: - Aggregates

    private func completedBookCount(in context: ModelContext) -> Int {
        let stats = ReadingStatsService.shared
        return CanonicalBibleBooks.all.filter { book in
            stats.chaptersReadInBook(book.name, in: context).count >= book.totalChapters
        }.count
    }

    private func devotionalReadCount(in context: ModelContext) -> Int {
        let marker = ReadingStatsService.devotionalBookName
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.bookName == marker }
        )
        return (try? context.fetch(descriptor).count) ?? 0
    }

    /// Total personal annotations — notes plus highlighted verses. Powers the
    /// "Notes" tier track, rewarding engagement with the study features.
    private func annotationCount(in context: ModelContext) -> Int {
        let notes = (try? context.fetchCount(FetchDescriptor<Note>())) ?? 0
        let highlights = (try? context.fetchCount(FetchDescriptor<HighlightedVerse>())) ?? 0
        return notes + highlights
    }

    private func allComplete(_ books: [String], in context: ModelContext, stats: ReadingStatsService) -> Bool {
        for book in books {
            let read = stats.chaptersReadInBook(book, in: context).count
            // CanonicalBibleBooks covers OT/NT; apocrypha gets handled separately
            guard let total = CanonicalBibleBooks.all.first(where: { $0.name == book })?.totalChapters else {
                // Book not in the canonical chapter-count table — fall back to "at least one"
                if read == 0 { return false }
                continue
            }
            if read < total { return false }
        }
        return true
    }

    private func chaptersReadOn(_ date: Date, in context: ModelContext) -> Int {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        let marker = ReadingStatsService.devotionalBookName
        let predicate = #Predicate<ReadingSession> { session in
            session.date >= day && session.date < nextDay && session.bookName != marker
        }
        let descriptor = FetchDescriptor<ReadingSession>(predicate: predicate)
        let sessions = (try? context.fetch(descriptor)) ?? []
        let unique = Set(sessions.map { "\($0.bookName)-\($0.chapterNumber)" })
        return unique.count
    }

    /// Whether any reading session (chapter or devotional) was recorded on the
    /// given calendar day. Used by liturgical-season badges that count showing
    /// up rather than a specific chapter (e.g. all four Sundays of Advent).
    private func hasAnySessionOn(_ date: Date, in context: ModelContext) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        let predicate = #Predicate<ReadingSession> { session in
            session.date >= day && session.date < nextDay
        }
        var descriptor = FetchDescriptor<ReadingSession>(predicate: predicate)
        descriptor.fetchLimit = 1
        return ((try? context.fetch(descriptor))?.isEmpty == false)
    }

    private func readChapter(book: String, chapter: Int, on date: Date, in context: ModelContext) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        let predicate = #Predicate<ReadingSession> { session in
            session.bookName == book && session.chapterNumber == chapter
                && session.date >= day && session.date < nextDay
        }
        let descriptor = FetchDescriptor<ReadingSession>(predicate: predicate)
        return (try? context.fetch(descriptor).isEmpty == false) ?? false
    }

    private func readChapterToday(book: String, in context: ModelContext) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: Date())
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        let predicate = #Predicate<ReadingSession> { session in
            session.bookName == book && session.date >= day && session.date < nextDay
        }
        let descriptor = FetchDescriptor<ReadingSession>(predicate: predicate)
        return (try? context.fetch(descriptor).isEmpty == false) ?? false
    }
}
