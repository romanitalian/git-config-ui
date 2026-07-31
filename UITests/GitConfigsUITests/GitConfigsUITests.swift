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

    /// Writes one PNG per sidebar section into `SCREENSHOTS_DIR` (set in the Xcode scheme as `$(SRCROOT)/screenshots`; shell env is not passed to UI tests).
    func testCaptureSectionScreenshots() throws {
        guard let dirString = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"], !dirString.isEmpty else {
            throw XCTSkip("SCREENSHOTS_DIR missing — regenerate Xcode project (xcodegen generate) so the scheme sets it")
        }
        let outputDir = URL(fileURLWithPath: dirString, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let app = XCUIApplication()
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10))

        for spec in Self.sectionScreenshotSpecs {
            let row = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier == %@", spec.accessibilityId))
                .element
            XCTAssertTrue(row.waitForExistence(timeout: 5), "Sidebar row \(spec.accessibilityId)")
            row.click()
            let shot = window.screenshot()
            let url = outputDir.appendingPathComponent(spec.fileName + ".png", isDirectory: false)
            try shot.pngRepresentation.write(to: url)
        }
    }

    private static let sectionScreenshotSpecs: [(accessibilityId: String, fileName: String)] = [
        ("sidebarSection-Users", "users"),
        ("sidebarSection-Aliases", "aliases"),
        ("sidebarSection-Core Settings", "core-settings"),
        ("sidebarSection-Credentials", "credentials"),
        ("sidebarSection-Diff & Merge", "diff-merge"),
        ("sidebarSection-About", "about"),
    ]
}
