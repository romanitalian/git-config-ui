import Foundation

final class GitConfigService {

    static let shared = GitConfigService()
    private init() {}

    // MARK: - Current User

    func loadCurrentUser(scope: ConfigScope = .global) -> (name: String, email: String) {
        let name  = readRaw("user.name",  scope: scope) ?? ""
        let email = readRaw("user.email", scope: scope) ?? ""
        return (name, email)
    }

    /// Absolute path to this work tree’s `config` file (handles worktrees / linked `.git`).
    func absoluteGitConfigFilePath(workTreePath: String) -> String? {
        let path = (workTreePath as NSString).standardizingPath
        guard !path.isEmpty else { return nil }

        if let out = runGit(["-C", path, "rev-parse", "--path-format=absolute", "--git-path", "config"])?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !out.isEmpty {
            return out
        }

        guard let gitDir = runGit(["-C", path, "rev-parse", "--absolute-git-dir"])?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !gitDir.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: gitDir, isDirectory: true).appendingPathComponent("config").path
    }

    /// Creates a new Git repository with `git init`. Returns `nil` on success, or an error message.
    func initializeRepository(workTreePath: String) -> String? {
        let path = (workTreePath as NSString).standardizingPath
        guard !path.isEmpty else { return "Invalid path." }

        let process = Process()
        let errPipe = Pipe()
        let outPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments     = ["-C", path, "init"]
        process.standardOutput = outPipe
        process.standardError  = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return error.localizedDescription
        }

        guard process.terminationStatus == 0 else {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            var errStr = String(data: errData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if errStr.isEmpty {
                return "git init failed (exit \(process.terminationStatus))."
            }
            if errStr.count > 300 {
                errStr = String(errStr.prefix(300)) + "…"
            }
            return errStr
        }

        return nil
    }

    // MARK: - Profiles (stored in global config as app metadata)

    func loadProfiles() -> [Profile] {
        guard let output = runGit(["config", "--global", "--get-regexp", "gituserchange-profile\\."]) else {
            return []
        }

        var profileMap: [String: Profile] = [:]

        for line in output.components(separatedBy: "\n") where !line.isEmpty {
            let parts = line.components(separatedBy: " ")
            guard parts.count >= 2 else { continue }

            let key   = parts[0]
            let value = parts.dropFirst().joined(separator: " ")

            let keyParts = key.components(separatedBy: ".")
            guard keyParts.count == 3 else { continue }

            let uuid  = keyParts[1]
            let field = keyParts[2]

            if profileMap[uuid] == nil { profileMap[uuid] = Profile(id: uuid) }

            switch field {
            case "label":    profileMap[uuid]?.label    = value
            case "name":     profileMap[uuid]?.name     = value
            case "email":    profileMap[uuid]?.email    = value
            case "type":     profileMap[uuid]?.isLocal  = (value == "local")
            case "repopath": profileMap[uuid]?.repoPath = value
            default: break
            }
        }

        return Array(profileMap.values)
            .sorted { $0.rowTitle.localizedCompare($1.rowTitle) == .orderedAscending }
            .map { applyLocalRepoIdentity($0) }
    }

    /// For local profiles, overlay `user.name` / `user.email` from that repo’s `.git/config` so Reload
    /// matches `git -C <repo> config` (metadata in ~/.gitconfig may be stale after external edits).
    private func applyLocalRepoIdentity(_ profile: Profile) -> Profile {
        guard profile.isLocal, !profile.repoPath.isEmpty else { return profile }
        let scope = ConfigScope.local(URL(fileURLWithPath: profile.repoPath))
        let n = readSetting("user.name", scope: scope)
        let e = readSetting("user.email", scope: scope)
        var p = profile
        if !n.isEmpty { p.name = n }
        if !e.isEmpty { p.email = e }
        return p
    }

    /// Activates a profile using its own scope (local if `profile.isLocal`, otherwise global).
    func activateProfile(_ profile: Profile) {
        let scope: ConfigScope = profile.isLocal
            ? .local(URL(fileURLWithPath: profile.repoPath))
            : .global
        activateProfile(profile, scope: scope)
    }

    /// Activates a profile into an explicit scope (used internally or for special cases).
    func activateProfile(_ profile: Profile, scope: ConfigScope) {
        setRaw("user.name",  value: profile.name,  scope: scope)
        setRaw("user.email", value: profile.email, scope: scope)
    }

    /// Returns true when the profile's name+email match the user config at the profile's own scope.
    func isProfileActive(_ profile: Profile) -> Bool {
        let scope: ConfigScope = profile.isLocal
            ? .local(URL(fileURLWithPath: profile.repoPath))
            : .global
        let n = readSetting("user.name",  scope: scope)
        let e = readSetting("user.email", scope: scope)
        return n == profile.name && e == profile.email
    }

    func saveProfile(_ profile: Profile) {
        let prefix = "gituserchange-profile.\(profile.id)"
        // `label` key kept for compatibility; mirror `user.name` (same as ProfileEditor / git user identity).
        _ = runGit(["config", "--global", "\(prefix).label", profile.name])
        _ = runGit(["config", "--global", "\(prefix).name",  profile.name])
        _ = runGit(["config", "--global", "\(prefix).email", profile.email])

        if profile.isLocal {
            _ = runGit(["config", "--global", "\(prefix).type",     "local"])
            _ = runGit(["config", "--global", "\(prefix).repopath", profile.repoPath])
        } else {
            // Clean up local-only keys if the profile was previously local
            _ = runGit(["config", "--global", "--unset-all", "\(prefix).type"])
            _ = runGit(["config", "--global", "--unset-all", "\(prefix).repopath"])
        }
    }

    func deleteProfile(_ profile: Profile) {
        _ = runGit(["config", "--global", "--remove-section", "gituserchange-profile.\(profile.id)"])

        // If the profile was local, remove the user override from that repo's .git/config
        // so it falls back to the global user automatically.
        if profile.isLocal && !profile.repoPath.isEmpty {
            let scope = ConfigScope.local(URL(fileURLWithPath: profile.repoPath))
            _ = runGit(scope.configArgs + ["--unset", "user.name"])
            _ = runGit(scope.configArgs + ["--unset", "user.email"])
        }
    }

    // MARK: - Aliases

    func loadAliases(scope: ConfigScope = .global) -> [Alias] {
        guard let output = runGit(scope.configArgs + ["--get-regexp", "--null", "alias\\."]) else {
            return []
        }
        return output
            .components(separatedBy: "\0")
            .filter { !$0.isEmpty }
            .compactMap { entry -> Alias? in
                guard let newlineIdx = entry.firstIndex(of: "\n") else { return nil }
                let keyPart = String(entry[entry.startIndex..<newlineIdx])
                let value   = String(entry[entry.index(after: newlineIdx)...])
                let key     = keyPart.replacingOccurrences(of: "alias.", with: "")
                guard !key.isEmpty else { return nil }
                return Alias(key: key, value: value)
            }
            .sorted { $0.key < $1.key }
    }

    func saveAlias(_ alias: Alias, scope: ConfigScope = .global) {
        _ = runGit(scope.configArgs + ["alias.\(alias.key)", alias.value])
    }

    func deleteAlias(key: String, scope: ConfigScope = .global) {
        _ = runGit(scope.configArgs + ["--unset", "alias.\(key)"])
    }

    // MARK: - Generic Settings

    func readSetting(_ key: String, scope: ConfigScope = .global) -> String {
        readRaw(key, scope: scope) ?? ""
    }

    func writeSetting(_ key: String, value: String, scope: ConfigScope = .global) {
        _ = runGit(scope.configArgs + [key, value])
    }

    func unsetSetting(_ key: String, scope: ConfigScope = .global) {
        _ = runGit(scope.configArgs + ["--unset", key])
    }

    // MARK: - Private

    private func readRaw(_ key: String, scope: ConfigScope) -> String? {
        runGit(scope.configArgs + [key])?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func setRaw(_ key: String, value: String, scope: ConfigScope) {
        _ = runGit(scope.configArgs + [key, value])
    }

    private func runGit(_ args: [String]) -> String? {
        let process = Process()
        let pipe    = Pipe()

        process.executableURL  = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments      = args
        process.standardOutput = pipe
        process.standardError  = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
