//
//  RedLetterTagStrippingTests.swift
//  swiftbibleTests
//
//  bible.json marks Jesus's words with <JESUS>…</JESUS> for red-letter
//  rendering. The daily-devotional Edge Function's selectRandomVerse() handed
//  verse text to the prompt without stripping them, so Aug 12, 2026 published
//  `"<JESUS>I am that bread of life. </JESUS>" John 6:48` verbatim. The
//  generator is fixed and the published rows backfilled; these pin the client
//  guard that keeps any future leak off the screen.
//
//  Mirrored on Android by
//  android/app/src/test/java/biz/am2/swiftbible/data/RedLetterTagStrippingTest.kt.
//

import XCTest
@testable import swiftbible

final class RedLetterTagStrippingTests: XCTestCase {

    func testStripsTagsFromTheBlockquoteThatShippedBroken() {
        let shipped = #"> *"<JESUS>I am that bread of life. </JESUS>"* **John 6:48**"#
        XCTAssertFalse(shipped.strippingRedLetterTags().contains("JESUS>"))
        XCTAssertEqual(
            shipped.strippingRedLetterTags(),
            #"> *"I am that bread of life. "* **John 6:48**"#
        )
    }

    func testKeepsSentenceSpacingInMixedNarrationAndRedLetterText() {
        let mixed = "And Jesus said, <JESUS>Follow me.</JESUS> Then he rose."
        XCTAssertEqual(mixed.strippingRedLetterTags(), "And Jesus said, Follow me. Then he rose.")
    }

    func testHandlesAVerseThatIsEntirelyRedLetter() {
        XCTAssertEqual(
            "<JESUS>Peace be unto you.</JESUS>".strippingRedLetterTags(),
            "Peace be unto you."
        )
    }

    /// 418 KJV paragraphs carry an inline verse number *between* two tags.
    /// Stripping the whitespace hugging those tags would yield "thee;5:24Leave".
    func testDoesNotJoinWordsAroundAnInlineVerseNumber() {
        let inline = "against thee; </JESUS>5:24<JESUS> Leave there thy gift"
        XCTAssertEqual(
            inline.strippingRedLetterTags(),
            "against thee; 5:24 Leave there thy gift"
        )
    }

    func testLeavesOrdinaryDevotionalProseUntouched() {
        let prose = "He whispered \"hello\" and left.\n\n## The synagogue\n\nDust clings to ankles."
        XCTAssertEqual(prose.strippingRedLetterTags(), prose)
    }

    func testStripsEveryOccurrenceInAMultiVerseDevotional() {
        let multi = "<JESUS>I am the way.</JESUS> ... <JESUS>Abide in me.</JESUS>"
        let result = multi.strippingRedLetterTags()
        XCTAssertFalse(result.contains("JESUS>"))
        XCTAssertEqual(result, "I am the way. ... Abide in me.")
    }

    /// The decode path is the actual choke point — every consumer (view,
    /// widget hand-off, notification teaser, saved devotionals) reads
    /// `message` after this.
    func testDecodingADevotionalStripsTagsFromMessage() throws {
        let json = Data(#"""
        {
          "id": 1,
          "message": "> *\"<JESUS>I am that bread of life. </JESUS>\"* **John 6:48**",
          "for_date": "2026-08-12",
          "devotional_type": "ai"
        }
        """#.utf8)

        let devotional = try JSONDecoder().decode(DailyDevotional.self, from: json)
        XCTAssertFalse(devotional.message.contains("JESUS>"))
        XCTAssertEqual(devotional.message, #"> *"I am that bread of life. "* **John 6:48**"#)
        XCTAssertEqual(devotional.for_date, "2026-08-12")
        XCTAssertEqual(devotional.devotional_type, "ai")
    }
}
