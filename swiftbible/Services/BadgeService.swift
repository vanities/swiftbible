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

            let badge = EarnedBadge(badgeId: definition.id, earnedAt: Date(), notified: false)
            context.insert(badge)
            newlyEarned.append(definition)

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
        default:
            return false
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
