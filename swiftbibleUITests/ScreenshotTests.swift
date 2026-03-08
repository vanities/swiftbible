//
//  ScreenshotTests.swift
//  swiftbibleUITests
//
//  Screenshot capture for App Store marketing assets.
//  Run with: xcodebuild test -project swiftbible.xcodeproj -scheme swiftbible
//            -destination 'platform=iOS Simulator,name=<device>'
//            -only-testing:swiftbibleUITests/ScreenshotTests
//

import XCTest

final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true

        app = XCUIApplication()
        app.launchArguments += [
            "-donationPromptOptOut", "YES",
            "-showApocrypha", "YES",
            "-showJewishPseudepigraphaEnoch", "YES",
            "-showJubilees", "YES",
            "-showTestaments", "YES",
            "-showSecondEnoch", "YES",
            "-showDidache", "YES",
            "-showFirstClement", "YES"
        ]
        app.launch()
    }

    @MainActor
    func testCaptureAllScreenshots() throws {
        // 1. Bible book list (home screen) - shows all text collections
        // Wait extra for iPad launch screen to dismiss
        let searchField = app.textFields["Search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 2)
        saveScreenshot(named: "01_bible_books")

        // 2. Chapter list - tap Genesis
        let genesis = app.staticTexts["Genesis"]
        XCTAssertTrue(genesis.waitForExistence(timeout: 10))
        genesis.tap()

        let chapter1 = app.staticTexts["Chapter 1"]
        XCTAssertTrue(chapter1.waitForExistence(timeout: 10))
        saveScreenshot(named: "02_chapters")

        // 3. Verse reading view - tap Chapter 1
        chapter1.tap()
        let verseText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "In the beginning")
        ).firstMatch
        XCTAssertTrue(verseText.waitForExistence(timeout: 10))
        saveScreenshot(named: "03_verses")

        // 4. Long press a verse to show verse options (Copy, Bookmark, Highlight, etc.)
        verseText.press(forDuration: 1.0)
        let explainButton = app.buttons["Explain"]
        if explainButton.waitForExistence(timeout: 5) {
            saveScreenshot(named: "04_verse_options")
            // Dismiss the action sheet
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.waitForExistence(timeout: 3) {
                cancelButton.tap()
            } else {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
            }
        }

        // 5. Show translation switcher (version menu in chapter view)
        Thread.sleep(forTimeInterval: 1)
        let versionButton = app.buttons["KJV"]
        if versionButton.waitForExistence(timeout: 3) {
            versionButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "05_translations")
            // Dismiss menu by tapping elsewhere
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        // 6. Daily Devotional tab
        tapTab(named: "Devotional")
        let devotionalView = app.descendants(matching: .any)["DailyDevotionalView"].firstMatch
        _ = devotionalView.waitForExistence(timeout: 15)
        Thread.sleep(forTimeInterval: 2)
        saveScreenshot(named: "06_devotional")

        // 7. Settings tab - shows Translations & Texts section
        tapTab(named: "Settings")
        Thread.sleep(forTimeInterval: 1)
        saveScreenshot(named: "07_settings")
    }

    // MARK: - Helpers

    private func tapTab(named label: String) {
        // Try tab bar first (iPhone)
        let tabButton = app.tabBars.buttons[label]
        if tabButton.waitForExistence(timeout: 3) {
            tabButton.tap()
            return
        }
        // iPad floating tab bar - use coordinate tap to avoid multiple match issues
        let button = app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
        if button.waitForExistence(timeout: 3) {
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
    }

    private func saveScreenshot(named name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
