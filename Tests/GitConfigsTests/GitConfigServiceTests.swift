import XCTest
@testable import GitConfigsLib

final class GitConfigServiceTests: XCTestCase {
    func testLoadProfilesEmptyWhenNoGitMetadata() throws {
        try TestHome.withTemporaryHome { _ in
            let profiles = GitConfigService.shared.loadProfiles()
            XCTAssertEqual(profiles, [])
        }
    }

    func testLoadProfilesAsyncUsesIsolatedHome() async throws {
        try await TestHome.withTemporaryHome { _ in
            let empty = await GitConfigService.shared.loadProfilesAsync()
            XCTAssertEqual(empty, [])

            let id = "33333333-3333-3333-3333-333333333333"
            let p = Profile(id: id, label: "", name: "Bob", email: "bob@example.com", isLocal: false, repoPath: "")
            await GitConfigService.shared.saveProfileAsync(p)
            let loaded = await GitConfigService.shared.loadProfilesAsync()
            XCTAssertEqual(loaded.count, 1)
            XCTAssertEqual(loaded[0].name, "Bob")
        }
    }

    func testSaveAndLoadGlobalProfileRoundTrip() throws {
        try TestHome.withTemporaryHome { _ in
            let svc = GitConfigService.shared
            let id = "11111111-1111-1111-1111-111111111111"
            let p = Profile(id: id, label: "", name: "Ada", email: "ada@example.com", isLocal: false, repoPath: "")
            svc.saveProfile(p)
            let loaded = svc.loadProfiles()
            XCTAssertEqual(loaded.count, 1)
            XCTAssertEqual(loaded[0].id, id)
            XCTAssertEqual(loaded[0].name, "Ada")
            XCTAssertEqual(loaded[0].email, "ada@example.com")
            XCTAssertFalse(loaded[0].isLocal)
        }
    }

    func testActivateProfileSetsGlobalUserAndIsActive() throws {
        try TestHome.withTemporaryHome { _ in
            let svc = GitConfigService.shared
            let p = Profile(
                id: "22222222-2222-2222-2222-222222222222",
                name: "Grace",
                email: "grace@example.com"
            )
            svc.saveProfile(p)
            svc.activateProfile(p)
            XCTAssertTrue(svc.isProfileActive(p))
            let current = svc.loadCurrentUser()
            XCTAssertEqual(current.name, "Grace")
            XCTAssertEqual(current.email, "grace@example.com")
        }
    }

    func testInitializeRepositoryCreatesGitRepo() throws {
        try TestHome.withTemporaryHome { home in
            let repo = home.appendingPathComponent("repo", isDirectory: true)
            try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
            let err = GitConfigService.shared.initializeRepository(workTreePath: repo.path)
            XCTAssertNil(err)
            let gitDir = repo.appendingPathComponent(".git")
            var isDir: ObjCBool = false
            XCTAssertTrue(FileManager.default.fileExists(atPath: gitDir.path, isDirectory: &isDir))
            XCTAssertTrue(isDir.boolValue)
        }
    }
}
