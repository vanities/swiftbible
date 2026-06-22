//
//  DailyDevotionalTests.swift
//  swiftbibleTests
//
//  Verifies devotional prose is safe to render after Bible red-letter markup
//  has been embedded in source verse text.
//

import XCTest
@testable import swiftbible

final class DailyDevotionalTests: XCTestCase {
    func testRemovingRedLetterTagsKeepsJesusWords() {
        let source = #"> "And he saith unto them, <JESUS>Are ye so without understanding also?</JESUS>" Mark 7:18"#

        XCTAssertEqual(
            source.removingRedLetterTags(),
            #"> "And he saith unto them, Are ye so without understanding also?" Mark 7:18"#
        )
    }

    func testRemovingRedLetterTagsHandlesWhitespaceAndCaseVariants() {
        let source = "<jesus>Peace be unto you.</ JESUS> < JESUS >Follow me.</jesus>"

        XCTAssertEqual(source.removingRedLetterTags(), "Peace be unto you. Follow me.")
    }

    func testCleanedForDisplaySanitizesMessageOnly() {
        let devotional = DailyDevotional(
            id: 7,
            message: "Before <JESUS>spoken words</JESUS> after",
            for_date: "2026-06-22",
            devotional_type: "single",
            series_name: nil,
            series_part: nil,
            holiday_name: nil,
            holiday_url: nil,
            anchor_verse: "Mark 7:18",
            verses: [DevotionalVerse(book: "Mark", chapter: 7, verse: 18, testament: "new")],
            model: "test-model",
            track: "narrative"
        )

        XCTAssertEqual(devotional.cleanedForDisplay.message, "Before spoken words after")
        XCTAssertEqual(devotional.cleanedForDisplay.anchor_verse, "Mark 7:18")
        XCTAssertEqual(devotional.cleanedForDisplay.verses, devotional.verses)
    }
}
