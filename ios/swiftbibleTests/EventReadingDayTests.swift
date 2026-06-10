//
//  EventReadingDayTests.swift
//  swiftbibleTests
//
//  Reading-plan dates are authored as UTC-midnight civil dates
//  (2026-05-25T00:00:00Z means "May 25"). Gating must unlock on the user's
//  LOCAL calendar day — never a day early west of UTC (the original bug),
//  never a day late east of UTC. These tests pin that contract with fixed
//  instants and fixed zones, independent of the machine's clock/timezone.
//

import XCTest
@testable import swiftbible

final class EventReadingDayTests: XCTestCase {

    private func makeCalendar(_ identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: identifier))
        return calendar
    }

    private func utcDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) throws -> Date {
        let utc = try makeCalendar("UTC")
        return try XCTUnwrap(utc.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute
        )))
    }

    func testDoesNotUnlockEarlyWestOfUTC() throws {
        let honolulu = try makeCalendar("Pacific/Honolulu") // UTC-10, no DST
        let authored = try utcDate(2026, 5, 25) // "May 25"

        // 09:00Z on May 25 is still 23:00 on May 24 in Honolulu — locked.
        let lateMay24Local = try utcDate(2026, 5, 25, hour: 9)
        XCTAssertFalse(EventReadingDay.hasArrived(authored, now: lateMay24Local, local: honolulu))

        // 10:00Z is the first instant of May 25 locally — unlocked.
        let may25Local = try utcDate(2026, 5, 25, hour: 10)
        XCTAssertTrue(EventReadingDay.hasArrived(authored, now: may25Local, local: honolulu))
    }

    func testUnlocksAtLocalMidnightEastOfUTC() throws {
        let auckland = try makeCalendar("Pacific/Auckland") // UTC+12 in May (NZST)
        let authored = try utcDate(2026, 5, 25)

        // 12:30Z on May 24 is already 00:30 on May 25 in Auckland — unlocked.
        let earlyMay25Local = try utcDate(2026, 5, 24, hour: 12, minute: 30)
        XCTAssertTrue(EventReadingDay.hasArrived(authored, now: earlyMay25Local, local: auckland))

        // 11:00Z on May 24 is 23:00 on May 24 locally — still locked.
        let lateMay24Local = try utcDate(2026, 5, 24, hour: 11)
        XCTAssertFalse(EventReadingDay.hasArrived(authored, now: lateMay24Local, local: auckland))
    }

    func testDaysUntilCountsLocalCivilDays() throws {
        let honolulu = try makeCalendar("Pacific/Honolulu")
        let authored = try utcDate(2026, 5, 27)
        // 12:00Z May 25 == 02:00 local May 25 → two local days to go.
        let now = try utcDate(2026, 5, 25, hour: 12)
        XCTAssertEqual(EventReadingDay.daysUntil(authored, now: now, local: honolulu), 2)
        XCTAssertEqual(EventReadingDay.daysUntil(authored, now: now, local: try makeCalendar("UTC")), 2)
    }

    func testIsTodayMatchesLocalCivilDate() throws {
        let honolulu = try makeCalendar("Pacific/Honolulu")
        let authored = try utcDate(2026, 5, 25)

        // 22:00Z May 25 == 12:00 local May 25 — it's "today".
        let noonLocalMay25 = try utcDate(2026, 5, 25, hour: 22)
        XCTAssertTrue(EventReadingDay.isToday(authored, now: noonLocalMay25, local: honolulu))

        // Same wall time a day later — no longer today.
        let noonLocalMay26 = try utcDate(2026, 5, 26, hour: 22)
        XCTAssertFalse(EventReadingDay.isToday(authored, now: noonLocalMay26, local: honolulu))
    }
}
