import XCTest

/// XCUITest bundle (built via `project.yml` + XcodeGen). Run with `make test-ui`.
final class GitConfigsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesAndShowsWindow() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 8))
    }
}
