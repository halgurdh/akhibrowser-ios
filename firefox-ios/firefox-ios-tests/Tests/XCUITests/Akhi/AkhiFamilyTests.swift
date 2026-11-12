// Copyright (c) 2026 the AkhiBrowser authors. All rights reserved.
// See LICENSE in the root of this repository.

import XCTest

/// The Family plan in a debug build: UITestAppDelegate unlocks it with AKHI_UITEST_FAMILY and turns the riba warning
/// on with AKHI_UITEST_FEATURES, so a Family feature of the pages can be seen working without a purchase.
class AkhiFamilyTests: BaseTestCase {
    static let ribaTitle = "This may involve riba (interest)"
    static let bnplSite = "https://www.klarna.com/"

    private var browserScreen: BrowserScreen!

    override func setUp() async throws {
        launchArguments.append("AKHI_UITEST_FEATURES")
        if !name.contains("WithoutFamily") {
            launchArguments.append("AKHI_UITEST_FAMILY")
        }
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
    }

    func testFamilyShowsTheRibaWarning() {
        browserScreen.navigateToURL(Self.bnplSite)
        waitUntilPageLoad(timeout: 30)
        let notice = app.webViews.staticTexts[Self.ribaTitle]
        XCTAssertTrue(notice.waitForExistence(timeout: 30), "No riba warning on \(Self.bnplSite)")
    }

    func testRibaWarningWithoutFamilyStaysOff() {
        browserScreen.navigateToURL(Self.bnplSite)
        waitUntilPageLoad(timeout: 30)
        let notice = app.webViews.staticTexts[Self.ribaTitle]
        XCTAssertFalse(notice.waitForExistence(timeout: 15), "The riba warning showed without Family")
    }
}
