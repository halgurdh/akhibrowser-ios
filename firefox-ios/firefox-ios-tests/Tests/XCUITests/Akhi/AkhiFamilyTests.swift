// Copyright (c) 2026 the AkhiBrowser authors. All rights reserved.
// See LICENSE in the root of this repository.

import XCTest

/// The Family plan in a debug (Fennec, developer channel) build: UITestAppDelegate unlocks it with AKHI_UITEST_FAMILY and turns the riba warning
/// on with AKHI_UITEST_FEATURES, so a Family feature of the pages can be seen working without a purchase.
class AkhiFamilyTests: BaseTestCase {
    static let ribaTitle = "This may involve riba (interest)"
    static let ribaText = NSPredicate(format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@", "riba (interest)", "riba (interest)")
    /// The riba warning knows a mortgage page by the words of its address.
    static let loanPage = "https://en.wikipedia.org/wiki/Mortgage_loan"

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
        browserScreen.navigateToURL(Self.loanPage)
        waitUntilPageLoad(timeout: 30)
        let notice = app.webViews.descendants(matching: .any).matching(Self.ribaText).firstMatch
        let shown = notice.waitForExistence(timeout: 30)
        if !shown {
            let texts = app.webViews.staticTexts.allElementsBoundByIndex.prefix(30).map(\.label)
            print("AkhiFamilyTests: texts of the page: \(texts)")
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "family-riba-missing"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        let state = app.descendants(matching: .any)["AkhiUITestState"]
        let stateText = state.exists ? state.label : "no AkhiUITestState"
        print("AkhiFamilyTests: \(stateText)")
        XCTAssertTrue(shown, "No riba warning on \(Self.loanPage). App: \(stateText)")
    }

    func testRibaWarningWithoutFamilyStaysOff() {
        browserScreen.navigateToURL(Self.loanPage)
        waitUntilPageLoad(timeout: 30)
        let notice = app.webViews.descendants(matching: .any).matching(Self.ribaText).firstMatch
        XCTAssertFalse(notice.waitForExistence(timeout: 15), "The riba warning showed without Family")
    }
}
