import Foundation

final class GitConfigService {

    static let shared = GitConfigService()
    private init() {}

    // MARK: - Current User

    func loadCurrentUser() -> (name: String, email: String) {
        let name = gitConfig("user.name") ?? ""
        let email = gitConfig("user.email") ?? ""
        return (name, email)
    }

    // MARK: - Profiles

    func loadProfiles() -> [Profile] {
        guard let output = runGit(["config", "--global", "--get-regexp", "gituserchange-profile\\."]) else {
            return []
        }

        var profileMap: [String: Profile] = [:]

        for line in output.components(separatedBy: "\n") where !line.isEmpty {
            // Format: gituserchange-profile.UUID.field value
            let parts = line.components(separatedBy: " ")
            guard parts.count >= 2 else { continue }

            let key = parts[0]
            let value = parts.dropFirst().joined(separator: " ")

            let keyParts = key.components(separatedBy: ".")
            guard keyParts.count == 3 else { continue }

            let uuid = keyParts[1]
            let field = keyParts[2]

            if profileMap[uuid] == nil {
                profileMap[uuid] = Profile(id: uuid)
            }

            switch field {
            case "label": profileMap[uuid]?.label = value
            case "name": profileMap[uuid]?.name = value
            case "email": profileMap[uuid]?.email = value
            default: break
            }
        }

        return Array(profileMap.values).sorted { $0.label.localizedCompare($1.label) == .orderedAscending }
    }

    // MARK: - Activate

    func activateProfile(_ profile: Profile) {
        setGitConfig("user.name", value: profile.name)
        setGitConfig("user.email", value: profile.email)
    }

    // MARK: - Save

    func saveProfile(_ profile: Profile) {
        let prefix = "gituserchange-profile.\(profile.id)"
        setGitConfig("\(prefix).label", value: profile.label)
        setGitConfig("\(prefix).name", value: profile.name)
        setGitConfig("\(prefix).email", value: profile.email)
    }

    // MARK: - Delete

    func deleteProfile(_ profile: Profile) {
        _ = runGit(["config", "--global", "--remove-section", "gituserchange-profile.\(profile.id)"])
    }

    // MARK: - Private

    private func gitConfig(_ key: String) -> String? {
        runGit(["config", "--global", key])?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func setGitConfig(_ key: String, value: String) {
        _ = runGit(["config", "--global", key, value])
    }

    private func runGit(_ args: [String]) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

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
