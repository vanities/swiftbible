//
//  ContentViewUITests
//  swiftbible
//
//  Created on 9/30/24.
//

import XCTest

final class ContentViewUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments += [
            "-donationPromptOptOut", "YES",
            "-showApocrypha", "YES"
        ]
        app.launch()
    }

    func testBibleVersesLoadAcrossAllTranslationsForOldAndNewTestaments() throws {
        let versions = ["KJV", "ASV", "WEB"]

        for version in versions {
            verifyVerseLoads(
                version: version,
                bookName: "Genesis",
                chapterNumber: 1,
                expectedTextFragment: "In the beginning"
            )

            navigateBackToBibleRoot()

            verifyVerseLoads(
                version: version,
                bookName: "Matthew",
                chapterNumber: 1,
                expectedTextFragment: "Jesus Christ"
            )

            navigateBackToBibleRoot()
        }
    }

    func testBookOfEnochAndApocryphaVersesLoad() throws {
        verifyVerseLoads(
            version: "KJV",
            bookName: "The Book of the Watchers",
            chapterNumber: 1,
            expectedTextFragment: "The words of the blessing of Enoch"
        )

        navigateBackToBibleRoot()

        verifyVerseLoads(
            version: "KJV",
            bookName: "Tobit",
            chapterNumber: 1,
            expectedTextFragment: "The book of the words of Tobit"
        )
    }

    func testDailyDevotionalLoads() throws {
        let devotionalTab = app.tabBars.buttons["Devotional"]
        XCTAssertTrue(devotionalTab.waitForExistence(timeout: 10), "Devotional tab should exist")
        devotionalTab.tap()

        let devotionalView = app.otherElements["DailyDevotionalView"]
        XCTAssertTrue(devotionalView.waitForExistence(timeout: 10), "Daily devotional view should exist")

        let emptyState = app.staticTexts["No devotional found for this day."]
        XCTAssertFalse(
            emptyState.waitForExistence(timeout: 20),
            "Expected today's devotional to load from production data"
        )
    }

    // MARK: - Helpers

    private func verifyVerseLoads(
        version: String,
        bookName: String,
        chapterNumber: Int,
        expectedTextFragment: String
    ) {
        openBibleTabIfNeeded()
        searchAndOpenBook(named: bookName)
        openChapter(number: chapterNumber)
        switchTranslationIfNeeded(to: version)

        let verseText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", expectedTextFragment)).firstMatch
        XCTAssertTrue(
            verseText.waitForExistence(timeout: 10),
            "Expected verse text containing '\(expectedTextFragment)' for \(bookName) \(chapterNumber) in \(version)"
        )
    }

    private func openBibleTabIfNeeded() {
        let bibleTab = app.tabBars.buttons["Bible"]
        XCTAssertTrue(bibleTab.waitForExistence(timeout: 5), "Bible tab should exist")
        if !bibleTab.isSelected {
            bibleTab.tap()
        }
    }

    private func searchAndOpenBook(named bookName: String) {
        let searchField = app.textFields["Search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 10), "Search field should exist")
        searchField.clearAndEnterText(bookName)

        let bookCell = app.staticTexts[bookName]
        XCTAssertTrue(bookCell.waitForExistence(timeout: 10), "Expected to find book \(bookName)")
        bookCell.tap()
    }

    private func openChapter(number: Int) {
        let chapterCell = app.staticTexts["Chapter \(number)"]
        XCTAssertTrue(chapterCell.waitForExistence(timeout: 10), "Expected chapter \(number) to exist")
        chapterCell.tap()
    }

    private func switchTranslationIfNeeded(to version: String) {
        if app.buttons[version].exists {
            return
        }

        let availableVersionButtons = ["KJV", "ASV", "WEB"]
        guard let currentVersionButton = availableVersionButtons.first(where: { app.buttons[$0].exists }) else {
            XCTFail("Could not find translation switcher button")
            return
        }

        app.buttons[currentVersionButton].tap()
        let targetOption = app.buttons[version]
        XCTAssertTrue(targetOption.waitForExistence(timeout: 5), "Expected translation option \(version)")
        targetOption.tap()

        XCTAssertTrue(app.buttons[version].waitForExistence(timeout: 5), "Expected translation button to switch to \(version)")
    }

    private func navigateBackToBibleRoot() {
        while app.navigationBars.buttons.element(boundBy: 0).exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()

            let searchField = app.textFields["Search"]
            if searchField.waitForExistence(timeout: 2) {
                break
            }
        }
    }
}

private extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        tap()

        guard let currentValue = value as? String else {
            typeText(text)
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteString)
        typeText(text)
    }
}
