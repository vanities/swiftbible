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

    /// Set via SCREENSHOT_SUFFIX env var (e.g. "_dark"). Appended to every
    /// saved screenshot filename so the same test can produce both light and
    /// dark sets without overwriting.
    private var screenshotSuffix: String = ""

    override func setUpWithError() throws {
        continueAfterFailure = true

        screenshotSuffix = ProcessInfo.processInfo.environment["SCREENSHOT_SUFFIX"] ?? ""
        let isDark = ProcessInfo.processInfo.environment["SCREENSHOT_DARK"] == "1"

        app = XCUIApplication()
        app.launchArguments += [
            "-donationPromptOptOut", "YES",
            "-showApocrypha", "YES",
            "-showJewishPseudepigraphaEnoch", "YES",
            "-showJubilees", "YES",
            "-showTestaments", "YES",
            "-showSecondEnoch", "YES",
            "-showDidache", "YES",
            "-showFirstClement", "YES",
            // Skip onboarding so the test lands directly on the Bible book list.
            "-onboardingHasLaunchedBefore", "YES",
            "-onboardingSeenFeatures", "welcome,dailyReminder,watchApp,widget,explain",
            // Pre-populate state so the More view shows a richer screenshot:
            // an existing bookmark + a recently-opened history article surface
            // the "Continue reading" / bookmark cards (Zeigarnik effect).
            "-bookmarkBookName", "Genesis",
            "-bookmarkChapterNumber", "3",
            "-bookmarkVerseNumber", "16",
            "-lastHistoryArticleId", "origins-timeline",
            "-lastHistoryArticleAt", "1746100000"
        ]
        if isDark {
            // Forces the app to run in dark appearance regardless of the
            // simulator's system setting.
            app.launchArguments += ["-AppleInterfaceStyle", "Dark"]
        }
        // Apple Intelligence isn't available in the simulator, so route the
        // Explain feature through MockExplainStream (DEBUG-only canned text).
        app.launchEnvironment["MOCK_EXPLAIN"] = "1"
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

        // 4. Show translation switcher FIRST (cleaner state — no popover to fight).
        // The button has .accessibilityLabel("Bible translation: ..."), which
        // overrides the visible "KJV" text for query matching, so we query by
        // accessibilityIdentifier instead.
        let versionButton = app.buttons["VersionPickerButton"]
        if versionButton.waitForExistence(timeout: 5) {
            versionButton.tap()
            let menuItem = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] %@", "King James Version")
            ).firstMatch
            _ = menuItem.waitForExistence(timeout: 3)
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "05_translations")
            // Dismiss the menu by re-tapping the picker button (iOS toggles)
            versionButton.tap()
            Thread.sleep(forTimeInterval: 0.7)
        } else {
            XCTFail("VersionPickerButton not found — translation switcher screenshot skipped")
        }

        // 5. Long press a verse to show verse options popover.
        // Re-query the verse text in case the view shifted while the menu was up.
        let verseTextForLongPress = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "In the beginning")
        ).firstMatch
        if verseTextForLongPress.waitForExistence(timeout: 5) {
            verseTextForLongPress.press(forDuration: 1.0)
            let explainButton = app.buttons["Explain"]
            if explainButton.waitForExistence(timeout: 5) {
                saveScreenshot(named: "04_verse_options")

                // 4b. Tap Explain to open the AI explanation sheet.
                // MOCK_EXPLAIN=1 routes through canned text so the simulator
                // (which can't run Apple Intelligence) produces a realistic
                // streaming result.
                explainButton.tap()
                // Mock streams ~28 tokens/sec; the body is ~80 tokens so it
                // finishes in ~3s. Wait long enough for visible body text.
                Thread.sleep(forTimeInterval: 4)
                saveScreenshot(named: "04b_explain")

                // Dismiss the explanation sheet via the Done button.
                let doneButton = app.buttons["Done"].firstMatch
                if doneButton.waitForExistence(timeout: 3) {
                    doneButton.tap()
                }
                Thread.sleep(forTimeInterval: 0.7)
            }
        }

        // 5b. Navigate to Matthew Chapter 5 (Sermon on the Mount) to capture
        //     a screen where Jesus's words appear in red — Genesis has none.
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()  // verses → chapters
            Thread.sleep(forTimeInterval: 0.4)
            backButton.tap()  // chapters → book list
            Thread.sleep(forTimeInterval: 0.6)
        }
        // Use the search field — deterministic across iPhone/iPad and avoids
        // long swipe sequences (Matthew is past 39 OT books + apocrypha).
        let bookSearchField = app.textFields["Search"]
        if bookSearchField.waitForExistence(timeout: 5) {
            bookSearchField.tap()
            bookSearchField.typeText("Matthew")
            Thread.sleep(forTimeInterval: 0.6)
            let matthew = app.staticTexts["Matthew"]
            if matthew.waitForExistence(timeout: 3) {
                matthew.tap()
                let chapter5 = app.staticTexts["Chapter 5"]
                if chapter5.waitForExistence(timeout: 5) {
                    chapter5.tap()
                    Thread.sleep(forTimeInterval: 1.2)
                    saveScreenshot(named: "03_red_letter")
                } else {
                    XCTFail("Matthew Chapter 5 not found — red letter screenshot skipped")
                }
            } else {
                XCTFail("Matthew not found via search — red letter screenshot skipped")
            }
        }

        // 6. Daily Devotional tab
        tapTab(named: "Devotional")
        let devotionalView = app.descendants(matching: .any)["DailyDevotionalView"].firstMatch
        _ = devotionalView.waitForExistence(timeout: 15)
        Thread.sleep(forTimeInterval: 2)
        saveScreenshot(named: "06_devotional")

        // 7. More tab - hub view with cards (Continue, Library, Stats, Settings, etc.)
        tapTab(named: "More")
        Thread.sleep(forTimeInterval: 1)
        saveScreenshot(named: "07_more")

        // 8. Settings - drill into the actual Settings view from MoreView's settings card
        // The card is a NavigationLink with a "gearshape.fill" icon — match by its title text.
        let settingsCard = app.staticTexts["Settings"].firstMatch
        if settingsCard.waitForExistence(timeout: 5) {
            settingsCard.tap()
            Thread.sleep(forTimeInterval: 1.2)
            saveScreenshot(named: "08_settings")
        } else {
            XCTFail("Settings card not found in MoreView — settings drill-in skipped")
        }

        // 9. Apocrypha section of the book list — captured LAST.
        // The Bible tab still has Matthew 5 in its nav stack from step 5b;
        // tap twice (iOS pops-to-root on the second tap of the active tab).
        tapTab(named: "Bible")
        Thread.sleep(forTimeInterval: 0.5)
        tapTab(named: "Bible")
        Thread.sleep(forTimeInterval: 0.8)

        // Clear the "Matthew" search filter from step 5b — otherwise the
        // book list shows only Matthew and scrolling won't reveal apocrypha.
        let searchFieldForClear = app.textFields["Search"]
        if searchFieldForClear.exists {
            // Tap the X button if present, or select-all + delete as fallback.
            let clearButton = searchFieldForClear.buttons["Clear text"]
            if clearButton.exists {
                clearButton.tap()
            } else {
                searchFieldForClear.tap()
                searchFieldForClear.press(forDuration: 1.2)
                let selectAll = app.menuItems["Select All"]
                if selectAll.waitForExistence(timeout: 2) {
                    selectAll.tap()
                }
                searchFieldForClear.typeText(XCUIKeyboardKey.delete.rawValue)
            }
            Thread.sleep(forTimeInterval: 0.5)
            // Dismiss keyboard so it doesn't cover the list.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        for _ in 0..<8 {
            app.swipeUp()
        }
        Thread.sleep(forTimeInterval: 0.6)
        saveScreenshot(named: "01b_apocrypha_books")
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
        attachment.name = "\(name)\(screenshotSuffix)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
