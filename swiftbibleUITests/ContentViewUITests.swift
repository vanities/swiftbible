//
//  ContentViewUITests
//  swiftbible
//
//  Created by Adam Mischke on 9/30/24.
//


import XCTest

final class ContentViewUITests: XCTestCase {

    // The app instance used in all tests
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Stop immediately when a failure occurs.
        continueAfterFailure = false

        // Initialize the app
        app = XCUIApplication()
        app.launch()
    }

    // Test that the initial selected tab is "Bible"
    func testInitialSelectedTabIsBible() throws {
        let bibleTab = app.tabBars.buttons["Bible"]
        XCTAssertTrue(bibleTab.exists, "Bible tab should exist")
        XCTAssertTrue(bibleTab.isSelected, "Bible tab should be selected by default")
    }

    // Test switching to the "Daily Devotional" tab
    func testSwitchToDailyDevotionalTab() throws {
        let dailyDevotionalTab = app.tabBars.buttons["Daily Devotional"]
        XCTAssertTrue(dailyDevotionalTab.exists, "Daily Devotional tab should exist")
        
        dailyDevotionalTab.tap()
        
        // Verify that DailyDevotionalView is displayed
        let devotionalView = app.scrollViews["DailyDevotionalView"]
        XCTAssertTrue(devotionalView.waitForExistence(timeout: 5), "Daily Devotional View should be displayed")
    }

    // Test switching to the "Search" tab
    func testSwitchToSearchTab() throws {
        let searchTab = app.tabBars.buttons["Search"]
        XCTAssertTrue(searchTab.exists, "Search tab should exist")
        
        searchTab.tap()
        
        // Verify that SearchDetailView is displayed
        let searchView = app.otherElements["SearchDetailView"]
        XCTAssertTrue(searchView.waitForExistence(timeout: 5), "Search Detail View should be displayed")
    }

    // Test switching to the "Settings" tab
    func testSwitchToSettingsTab() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        
        settingsTab.tap()
        
        // Verify that SettingsView is displayed
        let settingsView = app.collectionViews["SettingsView"]
        XCTAssertTrue(settingsView.waitForExistence(timeout: 5), "Settings View should be displayed")
    }
}
