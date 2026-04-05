import Foundation

enum ConfigScope: Equatable {
    case global
    case local(URL)

    var isLocal: Bool {
        if case .local = self { return true }
        return false
    }

    var repoURL: URL? {
        if case .local(let url) = self { return url }
        return nil
    }

    var repoName: String {
        repoURL?.lastPathComponent ?? "Local"
    }

    /// Args prefix for `git`, e.g. ["config", "--global"] or ["-C", "/path", "config", "--local"]
    var configArgs: [String] {
        switch self {
        case .global:
            return ["config", "--global"]
        case .local(let url):
            return ["-C", url.path, "config", "--local"]
        }
    }
}
