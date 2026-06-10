//
//  ReadingStatsServiceTests.swift
//  swiftbibleTests
//
//  Pins the streak / reading-stats date math. Streak scenarios are built
//  relative to the real "today" because the service anchors on it; every
//  assertion here is chosen to hold regardless of which weekday the tests
//  run on (the Sunday-sabbath rule only ever lengthens streaks).
//

import XCTest
import SwiftData
@testable import swiftbible

@MainActor
final class ReadingStatsServiceTests: XCTestCase {
    private var context: ModelContext!
    private let service = ReadingStatsService.shared

    override func setUp() async throws {
        context = try TestSupport.makeContext()
    }

    // MARK: - Current streak (freeze-aware)

    func testEmptyStoreHasNoStreak() {
        let info = service.currentStreakWithFreeze(in: context)
        XCTAssertEqual(info.streak, 0)
        XCTAssertFalse(info.freezeActive)
    }

    func testSingleReadTodayIsOneDayStreakWithoutFreeze() {
        TestSupport.insertSession(context)
        let info = service.currentStreakWithFreeze(in: context)
        XCTAssertEqual(info.streak, 1)
        XCTAssertFalse(info.freezeActive)
    }

    func testConsecutiveDaysCountTowardStreak() {
        for daysAgo in 0..<5 {
            TestSupport.insertSession(context, chapter: daysAgo + 1, daysAgo: daysAgo)
        }
        XCTAssertEqual(service.currentStreakWithFreeze(in: context).streak, 5)
    }

    func testStreakNotAliveWithoutTodayOrYesterday() {
        TestSupport.insertSession(context, daysAgo: 3)
        XCTAssertEqual(service.currentStreakWithFreeze(in: context).streak, 0)
    }

    func testSingleDayGapIsBridged() throws {
        // Read today, missed yesterday, read the two days before.
        TestSupport.insertSession(context, chapter: 1, daysAgo: 0)
        TestSupport.insertSession(context, chapter: 2, daysAgo: 2)
        TestSupport.insertSession(context, chapter: 3, daysAgo: 3)
        let info = service.currentStreakWithFreeze(in: context)
        XCTAssertEqual(info.streak, 3)

        // The gap is sabbath rest when yesterday was a Sunday (no freeze
        // consumed); any other weekday consumes the weekly freeze.
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let gapWasSunday = Calendar.current.component(.weekday, from: yesterday) == 1
        XCTAssertEqual(info.freezeActive, !gapWasSunday)
    }

    func testThreeMissedDaysBreakTheStreak() {
        // Any 3 consecutive missed days contain at least two non-Sundays,
        // which is more than one freeze + sabbath leniency can bridge.
        TestSupport.insertSession(context, chapter: 1, daysAgo: 0)
        TestSupport.insertSession(context, chapter: 2, daysAgo: 4)
        TestSupport.insertSession(context, chapter: 3, daysAgo: 5)
        XCTAssertEqual(service.currentStreakWithFreeze(in: context).streak, 1)
    }

    func testDevotionalMarkerCountsTowardStreakButNotChapterTotals() {
        service.logDevotionalRead(for: Date(), in: context)
        XCTAssertEqual(service.currentStreakWithFreeze(in: context).streak, 1)
        XCTAssertEqual(service.totalChaptersRead(in: context), 0)
    }

    func testLogDevotionalReadIsIdempotentPerDay() throws {
        service.logDevotionalRead(for: Date(), in: context)
        service.logDevotionalRead(for: Date(), in: context)
        let all = try context.fetch(FetchDescriptor<ReadingSession>())
        XCTAssertEqual(all.count, 1)
    }

    // MARK: - Longest streak (historical, strictly consecutive)

    func testLongestStreakFindsLongestConsecutiveRun() {
        // Anchored far in the past so "today" never interferes.
        // Runs: 400-398 (3 days), 395-392 (4 days), 380 (1 day).
        for daysAgo in [400, 399, 398, 395, 394, 393, 392, 380] {
            TestSupport.insertSession(context, chapter: daysAgo, daysAgo: daysAgo)
        }
        XCTAssertEqual(service.longestStreak(in: context), 4)
    }

    func testLongestStreakOfNothingIsZero() {
        XCTAssertEqual(service.longestStreak(in: context), 0)
    }

    // MARK: - Chapter "read" status

    func testReadChapterNumbersRequiresReachedEndAndDwell() {
        TestSupport.insertSession(context, chapter: 1, duration: 45, reachedEnd: true)   // counts
        TestSupport.insertSession(context, chapter: 2, duration: 10, reachedEnd: true)   // too short
        TestSupport.insertSession(context, chapter: 3, duration: 120, reachedEnd: false) // never reached end
        XCTAssertEqual(service.readChapterNumbers(forBook: "Genesis", in: context), [1])
    }

    func testReadDwellAccumulatesAcrossSessions() {
        TestSupport.insertSession(context, chapter: 1, duration: 20, reachedEnd: true)
        TestSupport.insertSession(context, chapter: 1, duration: 15, reachedEnd: false)
        XCTAssertEqual(service.readChapterNumbers(forBook: "Genesis", in: context), [1])
    }

    // MARK: - Aggregates

    func testTotalChaptersReadCountsDistinctChapters() {
        TestSupport.insertSession(context, chapter: 1)
        TestSupport.insertSession(context, chapter: 1)
        TestSupport.insertSession(context, chapter: 2)
        XCTAssertEqual(service.totalChaptersRead(in: context), 2)
    }

    func testChaptersReadInAllVersionsRequiresAllThree() {
        TestSupport.insertSession(context, chapter: 1, version: "kjv")
        TestSupport.insertSession(context, chapter: 1, version: "asv")
        XCTAssertEqual(service.chaptersReadInAllVersions(in: context), 0)
        TestSupport.insertSession(context, chapter: 1, version: "web")
        XCTAssertEqual(service.chaptersReadInAllVersions(in: context), 1)
    }
}
