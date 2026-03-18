//
//  ReadingStatsService.swift
//  swiftbible
//

import Foundation
import SwiftData

@MainActor
final class ReadingStatsService {
    static let shared = ReadingStatsService()

    private var currentSession: ReadingSession?
    private var modelContext: ModelContext?

    private init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func startReading(bookName: String, chapterNumber: Int, version: String) {
        // Don't restart if already tracking the same chapter
        if let current = currentSession,
           current.bookName == bookName,
           current.chapterNumber == chapterNumber,
           current.version == version {
            return
        }
        stopReading()
        currentSession = ReadingSession(bookName: bookName, chapterNumber: chapterNumber, version: version)
    }

    func stopReading() {
        guard let session = currentSession, let context = modelContext else {
            currentSession = nil
            return
        }
        let duration = Date().timeIntervalSince(session.startedAt)
        // Only record sessions longer than 5 seconds (skip navigation bounces and tab switches)
        if duration >= 5 {
            session.duration = duration
            context.insert(session)
            try? context.save()
        }
        currentSession = nil
    }

    // MARK: - Stats Queries

    func totalChaptersRead(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<ReadingSession>()
        let sessions = (try? context.fetch(descriptor)) ?? []
        let unique = Set(sessions.map { "\($0.bookName)-\($0.chapterNumber)" })
        return unique.count
    }

    func totalReadingTime(in context: ModelContext) -> TimeInterval {
        let descriptor = FetchDescriptor<ReadingSession>()
        let sessions = (try? context.fetch(descriptor)) ?? []
        return sessions.reduce(0) { $0 + $1.duration }
    }

    func currentStreak(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<ReadingSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let sessions = (try? context.fetch(descriptor)) ?? []

        let uniqueDays = Set(sessions.map { Calendar.current.startOfDay(for: $0.date) }).sorted(by: >)
        guard let first = uniqueDays.first else { return 0 }

        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        // Streak must include today or yesterday
        guard first >= yesterday else { return 0 }

        var streak = 1
        for i in 1..<uniqueDays.count {
            let expected = Calendar.current.date(byAdding: .day, value: -i, to: first)!
            if Calendar.current.isDate(uniqueDays[i], inSameDayAs: expected) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    func longestStreak(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<ReadingSession>(sortBy: [SortDescriptor(\.date, order: .forward)])
        let sessions = (try? context.fetch(descriptor)) ?? []

        let uniqueDays = Set(sessions.map { Calendar.current.startOfDay(for: $0.date) }).sorted()
        guard !uniqueDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for i in 1..<uniqueDays.count {
            let expected = Calendar.current.date(byAdding: .day, value: 1, to: uniqueDays[i - 1])!
            if Calendar.current.isDate(uniqueDays[i], inSameDayAs: expected) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    func sessionsThisWeek(in context: ModelContext) -> [ReadingSession] {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let predicate = #Predicate<ReadingSession> { $0.date >= startOfWeek }
        let descriptor = FetchDescriptor<ReadingSession>(predicate: predicate, sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func recentSessions(in context: ModelContext, limit: Int = 20) -> [ReadingSession] {
        var descriptor = FetchDescriptor<ReadingSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }
}
