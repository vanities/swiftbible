//
//  TestSupport.swift
//  swiftbibleTests
//

import Foundation
import SwiftData
@testable import swiftbible

@MainActor
enum TestSupport {
    /// Fresh in-memory store per test. `cloudKitDatabase: .none` keeps the
    /// CloudKit-backed production schema from trying to sync inside tests.
    static func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: ReadingSession.self, EarnedBadge.self, Note.self, HighlightedVerse.self,
            configurations: config
        )
        return ModelContext(container)
    }

    /// Inserts (and saves) a chapter-read session dated `daysAgo` days back.
    @discardableResult
    static func insertSession(
        _ context: ModelContext,
        book: String = "Genesis",
        chapter: Int = 1,
        version: String = "kjv",
        daysAgo: Int = 0,
        duration: TimeInterval = 60,
        reachedEnd: Bool = false
    ) -> ReadingSession {
        let session = ReadingSession(bookName: book, chapterNumber: chapter, version: version)
        let today = Calendar.current.startOfDay(for: Date())
        session.date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today) ?? today
        session.duration = duration
        session.reachedEnd = reachedEnd
        context.insert(session)
        try? context.save()
        return session
    }
}
