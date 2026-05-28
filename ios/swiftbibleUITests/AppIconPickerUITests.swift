//
//  AppIconPickerUITests.swift
//  ios/swiftbibleUITests
//

import XCTest

final class AppIconPickerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    /// Verify all icon preview images are bundled and loadable.
    @MainActor
    func testAllIconPreviewsLoadInPicker() throws {
        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10), "Settings tab should exist")
        settingsTab.tap()

        // Wait for settings to fully load
        sleep(2)

        // Find Donor Perks by searching all elements containing the text
        let predicate = NSPredicate(format: "label CONTAINS[c] 'Donor Perks'")
        let donorPerksElements = app.descendants(matching: .any).matching(predicate)

        if donorPerksElements.count == 0 {
            // Try scrolling
            app.swipeUp()
            sleep(1)
        }

        guard donorPerksElements.count > 0 else {
            // Debug: print what's visible
            let allTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }
            let allButtons = app.buttons.allElementsBoundByIndex.map { $0.label }
            XCTFail("Donor Perks not found. Visible texts: \(allTexts.prefix(20)), buttons: \(allButtons.prefix(20))")
            return
        }

        donorPerksElements.firstMatch.tap()
        sleep(1)

        // Find App Icon
        let appIconPredicate = NSPredicate(format: "label CONTAINS[c] 'App Icon'")
        let appIconElements = app.descendants(matching: .any).matching(appIconPredicate)

        guard appIconElements.count > 0 else {
            let allTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }
            XCTFail("App Icon not found in Donor Perks. Visible: \(allTexts.prefix(20))")
            return
        }

        appIconElements.firstMatch.tap()
        sleep(1)

        // All icon display names
        let expectedIcons = [
            "Default", "Classic", "Ivory", "Rose", "Ruby",
            "Ocean", "Midnight", "Sage", "Lavender", "Sunset",
            "Aurora", "Ember", "Frost", "Neon", "Copper",
            "Storm", "Blossom",
        ]

        var missingIcons: [String] = []
        var noPreviewIcons: [String] = []

        for iconName in expectedIcons {
            let iconPredicate = NSPredicate(format: "label == %@", iconName)
            let matches = app.staticTexts.matching(iconPredicate)

            // Scroll to find if not visible
            if matches.count == 0 {
                app.swipeUp()
                sleep(1)
            }

            if matches.count == 0 {
                missingIcons.append(iconName)
                continue
            }

            // Check the containing cell has an image
            let row = app.cells.containing(.staticText, identifier: iconName).firstMatch
            if row.exists && row.images.count == 0 {
                noPreviewIcons.append(iconName)
            }
        }

        XCTAssertTrue(missingIcons.isEmpty, "Missing icons in picker: \(missingIcons.joined(separator: ", "))")
        XCTAssertTrue(noPreviewIcons.isEmpty, "Icons without preview images: \(noPreviewIcons.joined(separator: ", "))")
    }
}
