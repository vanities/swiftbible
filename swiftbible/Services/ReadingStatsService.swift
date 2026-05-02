//
//  ReadingStatsService.swift
//  swiftbible
//

import Foundation
import SwiftData
import UIKit

@MainActor
final class ReadingStatsService {
    static let shared = ReadingStatsService()

    private var currentSession: ReadingSession?
    private var modelContext: ModelContext?

    // Total foreground time accumulated across all segments of the current session.
    // Background time is excluded so a chapter left open overnight doesn't record an 8h read.
    private var accumulatedDuration: TimeInterval = 0
    // Start of the current foreground segment; nil while backgrounded.
    private var segmentStartedAt: Date?

    private init() {
        observeAppLifecycle()
    }

    private func observeAppLifecycle() {
        let nc = NotificationCenter.default
        nc.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in self?.handleEnteredBackground() }
        }
        nc.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in self?.handleEnteredForeground() }
        }
        nc.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in self?.stopReading() }
        }
    }

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
        accumulatedDuration = 0
        segmentStartedAt = Date()
    }

    func stopReading() {
        guard let session = currentSession else {
            resetTrackingState()
            return
        }
        let total = currentForegroundDuration()
        // Only record sessions longer than 5 seconds (skip navigation bounces and tab switches)
        if total >= 5, let context = modelContext {
            session.duration = total
            context.insert(session)
            do {
                try context.save()
            } catch {
                SentryService.shared.capture(error, context: [
                    "service": "ReadingStatsService",
                    "operation": "save_session",
                    "book": session.bookName,
                    "chapter": session.chapterNumber,
                    "version": session.version
                ])
            }
        }
        resetTrackingState()
    }

    private func currentForegroundDuration() -> TimeInterval {
        var total = accumulatedDuration
        if let segmentStart = segmentStartedAt {
            total += Date().timeIntervalSince(segmentStart)
        }
        return total
    }

    private func resetTrackingState() {
        currentSession = nil
        accumulatedDuration = 0
        segmentStartedAt = nil
    }

    private func handleEnteredBackground() {
        guard let segmentStart = segmentStartedAt else { return }
        accumulatedDuration += Date().timeIntervalSince(segmentStart)
        segmentStartedAt = nil
    }

    private func handleEnteredForeground() {
        guard currentSession != nil, segmentStartedAt == nil else { return }
        segmentStartedAt = Date()
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

    // MARK: - Maintenance

    /// Deletes every recorded reading session. Also clears any in-memory tracking
    /// so a session in progress when this is called doesn't immediately re-insert.
    func resetAllSessions(in context: ModelContext) {
        resetTrackingState()
        do {
            try context.delete(model: ReadingSession.self)
            try context.save()
        } catch {
            SentryService.shared.capture(error, context: [
                "service": "ReadingStatsService",
                "operation": "reset_all_sessions"
            ])
        }
    }
}
