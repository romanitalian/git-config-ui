import Foundation

/// Runs `body` with `HOME` pointing at a fresh temporary directory, then restores the previous value.
enum TestHome {
    static func withTemporaryHome(_ body: (URL) throws -> Void) throws {
        let home = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitConfigsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        let previous = ProcessInfo.processInfo.environment["HOME"]
        setenv("HOME", home.path, 1)
        defer {
            if let p = previous {
                setenv("HOME", p, 1)
            } else {
                unsetenv("HOME")
            }
            try? FileManager.default.removeItem(at: home)
        }
        try body(home)
    }
}
