//
//  Runshaw_BusUITests.swift
//  Runshaw BusUITests
//
//  Created by Jacob on 24/04/2026.
//

import XCTest

final class BusesUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestingStubData"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Launch

    func testDeparturesHeadingVisible() {
        XCTAssertTrue(app.staticTexts["Departures"].waitForExistence(timeout: 3))
    }

    // MARK: - Filter pills

    func testFilterPillsAllPresent() {
        XCTAssertTrue(app.buttons["All"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Arrived"].exists)
        XCTAssertTrue(app.buttons["Waiting"].exists)
    }

    func testArrivedFilterHidesWaitingRoutes() {
        XCTAssertTrue(app.staticTexts["800"].waitForExistence(timeout: 3))
        app.buttons["Arrived"].tap()
        XCTAssertTrue(app.staticTexts["800"].exists)
        XCTAssertTrue(app.staticTexts["819"].exists)
        waitForGone(app.staticTexts["961"])
    }

    func testWaitingFilterHidesArrivedRoutes() {
        XCTAssertTrue(app.staticTexts["961"].waitForExistence(timeout: 3))
        app.buttons["Waiting"].tap()
        XCTAssertTrue(app.staticTexts["961"].exists)
        waitForGone(app.staticTexts["800"])
        waitForGone(app.staticTexts["819"])
    }

    func testAllFilterRestoresFullList() {
        XCTAssertTrue(app.staticTexts["800"].waitForExistence(timeout: 3))
        app.buttons["Arrived"].tap()
        app.buttons["All"].tap()
        XCTAssertTrue(app.staticTexts["961"].waitForExistence(timeout: 2))
    }

    // MARK: - Search

    func testSearchNarrowsResults() {
        let field = app.textFields["Route number"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("800")
        XCTAssertTrue(app.staticTexts["800"].exists)
        waitForGone(app.staticTexts["961"])
        waitForGone(app.staticTexts["819"])
    }

    func testClearSearchRestoresResults() {
        let field = app.textFields["Route number"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("800")
        let clear = app.buttons["Clear search"]
        XCTAssertTrue(clear.waitForExistence(timeout: 2))
        clear.tap()
        XCTAssertTrue(app.staticTexts["961"].waitForExistence(timeout: 2))
    }

    // MARK: - Favouriting

    func testLiveActivityButtonDisabledWithNoFavourites() {
        XCTAssertTrue(app.staticTexts["Departures"].waitForExistence(timeout: 3))
        let bell = app.buttons["Live Activity"]
        XCTAssertTrue(bell.waitForExistence(timeout: 3))
        XCTAssertFalse(bell.isEnabled)
    }

    // MARK: - Helpers

    private func waitForGone(_ element: XCUIElement, timeout: TimeInterval = 2) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        wait(for: [gone], timeout: timeout)
    }

    func testFavouritingIsToggleable() {
        XCTAssertTrue(app.staticTexts["800"].waitForExistence(timeout: 3))
        let bell = app.buttons["Live Activity"]
        XCTAssertFalse(bell.isEnabled)
        app.staticTexts["800"].tap()
        XCTAssertTrue(bell.waitForExistence(timeout: 2))
        XCTAssertTrue(bell.isEnabled)
        app.staticTexts["800"].tap()
        XCTAssertFalse(bell.isEnabled)
    }
}
