//
//  IntroMarkupTests.swift
//  swiftbibleTests
//
//  The "About this book" intros carry a two-construct markup written by
//  python_parser/parse_book_intros.py: "## " headings and "**bold**" runs.
//  These pin how BookIntroView reads it, so a stray "**" can never render as
//  literal asterisks or embolden the rest of a paragraph.
//
//  Mirrored on Android by
//  android/app/src/test/java/biz/am2/swiftbible/data/IntroMarkupTest.kt.
//

import XCTest
@testable import swiftbible

final class IntroMarkupTests: XCTestCase {

    func testAHeadingParagraphYieldsItsTitle() {
        XCTAssertEqual(IntroMarkup.heading("## Where Job Lived"), "Where Job Lived")
    }

    func testABodyParagraphIsNotAHeading() {
        XCTAssertNil(IntroMarkup.heading("Uz, according to Gesenius, means a light soil."))
        XCTAssertNil(IntroMarkup.heading("##No space is not a heading"))
    }

    func testPlainTextIsOneRun() {
        XCTAssertEqual(
            IntroMarkup.runs("As to the name Job—repentance—it was common."),
            [.init(text: "As to the name Job—repentance—it was common.", isBold: false)]
        )
    }

    func testBoldRunsAlternateWithPlainOnes() {
        XCTAssertEqual(
            IntroMarkup.runs("we must enquire, **I.** Into the divine authority of it. **II.** As to"),
            [
                .init(text: "we must enquire, ", isBold: false),
                .init(text: "I.", isBold: true),
                .init(text: " Into the divine authority of it. ", isBold: false),
                .init(text: "II.", isBold: true),
                .init(text: " As to", isBold: false)
            ]
        )
    }

    func testAParagraphOpeningInBold() {
        XCTAssertEqual(
            IntroMarkup.runs("**II.** To lead to Christ"),
            [.init(text: "II.", isBold: true), .init(text: " To lead to Christ", isBold: false)]
        )
    }

    func testAnUnpairedMarkerStaysLiteral() {
        XCTAssertEqual(
            IntroMarkup.runs("The **time of writing** was 2 ** 3"),
            [
                .init(text: "The ", isBold: false),
                .init(text: "time of writing", isBold: true),
                .init(text: " was 2 ** 3", isBold: false)
            ]
        )
    }

    func testRunsReassembleTheTextWithoutMarkup() {
        let paragraph = "His **purpose**, then: **(1)** to defend; **(2)** to warn."
        XCTAssertEqual(
            IntroMarkup.runs(paragraph).map(\.text).joined(),
            paragraph.replacingOccurrences(of: "**", with: "")
        )
    }
}
