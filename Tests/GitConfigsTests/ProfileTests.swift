import XCTest
@testable import GitConfigsLib

final class ProfileTests: XCTestCase {
    func testRowTitlePrefersNameOverLabel() {
        let p = Profile(id: "id", label: "Legacy", name: "Shown", email: "a@b.c")
        XCTAssertEqual(p.rowTitle, "Shown")
    }

    func testRowTitleFallsBackToLabelWhenNameEmpty() {
        let p = Profile(id: "id", label: "OnlyLabel", name: "", email: "a@b.c")
        XCTAssertEqual(p.rowTitle, "OnlyLabel")
    }
}
