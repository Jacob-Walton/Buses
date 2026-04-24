//
//  Runshaw_BusTests.swift
//  Runshaw BusTests
//
//  Created by Jacob on 24/04/2026.
//

import XCTest
@testable import Runshaw_Bus

final class BusesTests: XCTestCase {

    // MARK: - Bus model

    func testHasArrivedWhenBaySet() {
        let bus = Bus(id: 0, number: "800", bay: "A7")
        XCTAssertTrue(bus.hasArrived)
    }

    func testNotArrivedWhenTBC() {
        let bus = Bus(id: 0, number: "800", bay: "TBC")
        XCTAssertFalse(bus.hasArrived)
    }

    // MARK: - Window logic

    func testWindowStart() {
        var comps = DateComponents()
        comps.weekday = 2 // Monday
        comps.hour = 15
        comps.minute = 0
        let date = Calendar.current.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime)!
        XCTAssertTrue(BackgroundRefresh.isInWindow(date))
    }

    func testBeforeWindowStart() {
        var comps = DateComponents()
        comps.weekday = 2
        comps.hour = 14
        comps.minute = 59
        let date = Calendar.current.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime)!
        XCTAssertFalse(BackgroundRefresh.isInWindow(date))
    }

    func testWindowEnd() {
        var comps = DateComponents()
        comps.weekday = 2
        comps.hour = 16
        comps.minute = 30
        let date = Calendar.current.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime)!
        XCTAssertTrue(BackgroundRefresh.isInWindow(date))
    }

    func testAfterWindowEnd() {
        var comps = DateComponents()
        comps.weekday = 2
        comps.hour = 16
        comps.minute = 31
        let date = Calendar.current.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime)!
        XCTAssertFalse(BackgroundRefresh.isInWindow(date))
    }

    func testWeekendOutsideWindow() {
        var comps = DateComponents()
        comps.weekday = 1 // Sunday
        comps.hour = 15
        comps.minute = 30
        let date = Calendar.current.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime)!
        XCTAssertFalse(BackgroundRefresh.isInWindow(date))
    }

    // MARK: - Notification de-dup

    func testMarkNotifiedRoundTrip() {
        let suiteName = "test.buses.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let route = "800"
        let key = "lastNotified_\(route)"

        XCTAssertNil(defaults.object(forKey: key))

        defaults.set(Date(), forKey: key)
        let stored = defaults.object(forKey: key) as? Date
        XCTAssertNotNil(stored)
        XCTAssertTrue(Calendar.current.isDateInToday(stored!))
    }

    func testHasNotNotifiedWhenNoEntry() {
        let suiteName = "test.buses.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertNil(defaults.object(forKey: "lastNotified_999"))
    }

    // MARK: - HTML parsing

    func testParseValidHTML() throws {
        let html = """
        <html><body>
        <table id="grdAll"><tbody>
        <tr><td>800</td><td></td><td>A7</td></tr>
        <tr><td>961</td><td></td><td>TBC</td></tr>
        </tbody></table>
        </body></html>
        """
        let buses = try ApiService().parseHTML(html)
        XCTAssertEqual(buses.count, 2)
        XCTAssertEqual(buses[0].number, "800")
        XCTAssertEqual(buses[0].bay, "A7")
        XCTAssertTrue(buses[0].hasArrived)
        XCTAssertEqual(buses[1].number, "961")
        XCTAssertEqual(buses[1].bay, "TBC")
        XCTAssertFalse(buses[1].hasArrived)
    }

    func testParseEmptyTable() throws {
        let html = "<html><body><table id=\"grdAll\"><tbody></tbody></table></body></html>"
        let buses = try ApiService().parseHTML(html)
        XCTAssertTrue(buses.isEmpty)
    }

    func testParseMissingTable() throws {
        let html = "<html><body></body></html>"
        let buses = try ApiService().parseHTML(html)
        XCTAssertTrue(buses.isEmpty)
    }

    func testParseBayEmptyBecomessTBC() throws {
        let html = """
        <html><body>
        <table id="grdAll"><tbody>
        <tr><td>142</td><td></td><td></td></tr>
        </tbody></table>
        </body></html>
        """
        let buses = try ApiService().parseHTML(html)
        XCTAssertEqual(buses.first?.bay, "TBC")
        XCTAssertFalse(buses.first?.hasArrived ?? true)
    }
}
