// Copyright (c) 2026 the AkhiBrowser authors. All rights reserved.
// See LICENSE in the root of this repository.

import Common
import XCTest

/// AkhiKit's protection inside the app: pages typed in the address bar are blocked, rewritten or get SafeSearch.
class AkhiProtectionTests: BaseTestCase {
    static let blockedTitle = "This page is blocked"
    static let goBack = "Go back"

    private var browserScreen: BrowserScreen!

    override func setUp() async throws {
        // the address bar shows the URL of a search, not its terms
        launchArguments += [
            "\(LaunchArguments.LoadExperiment)searchTermInAddressBarOff",
            "\(LaunchArguments.ExperimentFeatureName)toolbar-refactor-feature"
        ]
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
    }

    func testOrdinarySiteOpens() {
        browserScreen.navigateToURL("https://www.wikipedia.org/")
        waitUntilPageLoad(timeout: 30)
        XCTAssertFalse(app.alerts[Self.blockedTitle].exists)
        browserScreen.assertAddressBarContains(value: "wikipedia.org", timeout: 30)
    }

    func testAdultSiteIsBlocked() {
        assertBlocked("https://www.pornhub.com/")
    }

    func testAdultSubdomainIsBlocked() {
        assertBlocked("https://fr.pornhub.com/")
    }

    func testAdultSearchIsBlocked() {
        assertBlocked("https://www.bing.com/search?q=porn")
    }

    func testHaramPurchaseSearchIsBlocked() {
        assertBlocked("https://www.google.com/search?q=buy+beer")
    }

    func testHaramSearchBecomesAQuestion() {
        assertAddress(after: "https://www.google.com/search?q=beer", containsAnyOf: ["why"])
    }

    func testGoogleGetsSafeSearch() {
        // Google's robot check keeps the search in its continue parameter
        assertAddress(after: "https://www.google.com/search?q=test", containsAnyOf: ["safe=active", "safe%3Dactive"])
    }

    func testBingGetsSafeSearch() {
        assertAddress(after: "https://www.bing.com/search?q=test", containsAnyOf: ["adlt=strict", "adlt%3Dstrict"])
    }

    private func assertBlocked(_ url: String, file: StaticString = #filePath, line: UInt = #line) {
        browserScreen.navigateToURL(url)
        let alert = app.alerts[Self.blockedTitle]
        XCTAssertTrue(alert.waitForExistence(timeout: 30), "\(url) wasn't blocked", file: file, line: line)
        alert.buttons[Self.goBack].tap()
        mozWaitForElementToNotExist(alert)
    }

    private func assertAddress(
        after url: String,
        containsAnyOf parts: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        browserScreen.navigateToURL(url)
        waitUntilPageLoad(timeout: 30)
        XCTAssertFalse(app.alerts[Self.blockedTitle].exists, "\(url) was blocked", file: file, line: line)
        browserScreen.tapOnAddressBar()
        let addressBar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        let format = parts.map { _ in "value CONTAINS %@" }.joined(separator: " OR ")
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: format, argumentArray: parts),
            object: addressBar
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: 30)
        XCTAssertEqual(
            result,
            .completed,
            "The address \(addressBar.value as? String ?? "?") has none of \(parts)",
            file: file,
            line: line
        )
        browserScreen.tapCancelButtonOnUrlBarExist()
    }
}
