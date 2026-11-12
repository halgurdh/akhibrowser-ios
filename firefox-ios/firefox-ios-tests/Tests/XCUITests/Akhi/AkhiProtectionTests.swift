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
        XCTAssertFalse(app.alerts[Self.blockedTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 30), "Wikipedia didn't open")
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

    /// The address of the page after a search: the bar shows a search's terms, so the address is copied from its menu
    /// and pasted back into it as text.
    private func assertAddress(
        after url: String,
        containsAnyOf parts: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let selectors = BrowserSelectors()
        browserScreen.navigateToURL(url)
        waitUntilPageLoad(timeout: 30)
        XCTAssertFalse(app.alerts[Self.blockedTitle].exists, "\(url) was blocked", file: file, line: line)
        UIPasteboard.general.string = "nothing-copied"
        // the address bar's menu sometimes doesn't open while the page still settles
        let copyAddress = selectors.CONTEXT_MENU_COPY_ADDRESS.element(in: app)
        for _ in 1...3 {
            selectors.ADDRESS_BAR.element(in: app).press(forDuration: 1.5)
            if copyAddress.waitForExistence(timeout: 5) { break }
            app.tap()
            sleep(2)
        }
        copyAddress.waitAndTap()

        browserScreen.tapOnAddressBar()
        selectors.CLEAR_TEXT_BUTTON.element(in: app).tapIfExists()
        let addressBar = selectors.ADDRESS_BAR.element(in: app)
        // the edit menu's Paste is a button, a menu item or, on iOS 26, a static text
        let paste = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == 'Paste' AND elementType IN %@", [
                XCUIElement.ElementType.button.rawValue,
                XCUIElement.ElementType.menuItem.rawValue,
                XCUIElement.ElementType.staticText.rawValue,
            ]))
            .firstMatch
        addressBar.press(forDuration: 1)
        if !paste.waitForExistence(timeout: 5) {
            addressBar.press(forDuration: 1)
        }
        paste.waitAndTap()

        let format = parts.map { _ in "value CONTAINS %@" }.joined(separator: " OR ")
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: format, argumentArray: parts),
            object: addressBar
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: 15)
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
