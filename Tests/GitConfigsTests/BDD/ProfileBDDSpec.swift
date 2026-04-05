import Nimble
import Quick
import XCTest
@testable import GitConfigsLib

/// BDD-style scenarios (Quick/Nimble) for profile display rules.
final class ProfileBDDSpec: QuickSpec {
    override static func spec() {
        describe("Profile row title") {
            context("when name is non-empty") {
                it("shows the name") {
                    let profile = Profile(id: "x", label: "Old", name: "Bob", email: "b@b.c")
                    expect(profile.rowTitle) == "Bob"
                }
            }
            context("when name is empty") {
                it("falls back to label") {
                    let profile = Profile(id: "y", label: "Fallback", name: "", email: "b@b.c")
                    expect(profile.rowTitle) == "Fallback"
                }
            }
        }
    }
}
