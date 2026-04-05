import XCTest
@testable import GitConfigsLib

final class ConfigScopeTests: XCTestCase {
    func testGlobalConfigArgs() {
        XCTAssertEqual(ConfigScope.global.configArgs, ["config", "--global"])
    }

    func testLocalConfigArgsUsesRepoPath() {
        let path = "/tmp/example-repo"
        let scope = ConfigScope.local(URL(fileURLWithPath: path))
        XCTAssertEqual(scope.configArgs, ["-C", path, "config", "--local"])
        XCTAssertTrue(scope.isLocal)
    }

    func testRepoNameFromURL() {
        let scope = ConfigScope.local(URL(fileURLWithPath: "/Users/dev/myproject"))
        XCTAssertEqual(scope.repoName, "myproject")
    }
}
