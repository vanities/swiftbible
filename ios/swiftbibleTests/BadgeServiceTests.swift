//
//  BadgeServiceTests.swift
//  swiftbibleTests
//
//  Pins badge unlock conditions. Assertions use `contains` rather than
//  equality so unrelated registry additions (or host-app UserDefaults state
//  feeding event/devotional badges) can't break them.
//

import XCTest
import SwiftData
@testable import swiftbible

@MainActor
final class BadgeServiceTests: XCTestCase {
    private var context: ModelContext!

    override func setUp() async throws {
        context = try TestSupport.makeContext()
    }

    func testSevenDayStreakEarnsBronzeStreakBadge() {
        for daysAgo in 0..<7 {
            TestSupport.insertSession(context, chapter: daysAgo + 1, daysAgo: daysAgo)
        }
        let earned = BadgeService.shared.checkBadges(in: context)
        XCTAssertTrue(earned.contains { $0.id == "tier.streak.bronze" })
        XCTAssertEqual(BadgeService.shared.currentTier(track: .streak, in: context), .bronze)
    }

    func testChapterBadgeNotEarnedBelowThreshold() {
        for chapter in 1...10 {
            TestSupport.insertSession(context, chapter: chapter)
        }
        let earned = BadgeService.shared.checkBadges(in: context)
        XCTAssertFalse(earned.contains { $0.track == .chapters })
    }

    func testFiftyChaptersEarnsBronzeChaptersBadge() {
        for chapter in 1...50 {
            TestSupport.insertSession(context, chapter: chapter)
        }
        let earned = BadgeService.shared.checkBadges(in: context)
        XCTAssertTrue(earned.contains { $0.id == "tier.chapters.bronze" })
    }

    func testCheckBadgesDoesNotAwardDuplicates() {
        for daysAgo in 0..<7 {
            TestSupport.insertSession(context, chapter: daysAgo + 1, daysAgo: daysAgo)
        }
        let first = BadgeService.shared.checkBadges(in: context)
        XCTAssertFalse(first.isEmpty)
        let second = BadgeService.shared.checkBadges(in: context)
        XCTAssertTrue(second.isEmpty)
    }

    func testMarathonHiddenBadgeAfterTenChaptersInADay() {
        for chapter in 1...10 {
            TestSupport.insertSession(context, chapter: chapter)
        }
        let earned = BadgeService.shared.checkBadges(in: context)
        XCTAssertTrue(earned.contains { $0.id == "hidden.marathon" })
    }

    func testNightOwlRequiresSmallHours() throws {
        TestSupport.insertSession(context)
        let oneAM = try XCTUnwrap(
            Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date())
        )
        let earned = BadgeService.shared.checkBadges(in: context, triggerDate: oneAM)
        XCTAssertTrue(earned.contains { $0.id == "hidden.night.owl" })
    }

    func testScribeBadgeCountsNotesAndHighlights() throws {
        for verse in 1...3 {
            context.insert(Note(
                version: "kjv", book: "Genesis", chapter: 1,
                startingVerse: verse, text: "note", created: .now
            ))
        }
        for verse in 4...5 {
            context.insert(HighlightedVerse(
                version: "kjv", book: "Genesis", chapter: 1,
                startingVerse: verse, color: "FFFFE0"
            ))
        }
        try context.save()
        let earned = BadgeService.shared.checkBadges(in: context)
        XCTAssertTrue(earned.contains { $0.id == "tier.scribe.bronze" })
    }
}
