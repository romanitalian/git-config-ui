import Foundation

extension GitConfigService {

    func performOffMain<T>(_ work: @escaping @Sendable () -> T) async -> T {
        await Task.detached(priority: .userInitiated) { work() }.value
    }

    func loadProfilesAsync() async -> [Profile] {
        await performOffMain { self.loadProfiles() }
    }

    func activateProfileAsync(_ profile: Profile) async {
        await performOffMain { self.activateProfile(profile) }
    }

    func deleteProfileAsync(_ profile: Profile) async {
        await performOffMain { self.deleteProfile(profile) }
    }

    func saveProfileAsync(_ profile: Profile) async {
        await performOffMain { self.saveProfile(profile) }
    }

    func isProfileActiveAsync(_ profile: Profile) async -> Bool {
        await performOffMain { self.isProfileActive(profile) }
    }

    func loadAliasesAsync(scope: ConfigScope = .global) async -> [Alias] {
        await performOffMain { self.loadAliases(scope: scope) }
    }

    func saveAliasAsync(_ alias: Alias, scope: ConfigScope = .global) async {
        await performOffMain { self.saveAlias(alias, scope: scope) }
    }

    func deleteAliasAsync(key: String, scope: ConfigScope = .global) async {
        await performOffMain { self.deleteAlias(key: key, scope: scope) }
    }

    func readSettingAsync(_ key: String, scope: ConfigScope = .global) async -> String {
        await performOffMain { self.readSetting(key, scope: scope) }
    }

    func writeSettingAsync(_ key: String, value: String, scope: ConfigScope = .global) async {
        await performOffMain { self.writeSetting(key, value: value, scope: scope) }
    }

    func unsetSettingAsync(_ key: String, scope: ConfigScope = .global) async {
        await performOffMain { self.unsetSetting(key, scope: scope) }
    }

    func initializeRepositoryAsync(workTreePath: String) async -> String? {
        await performOffMain { self.initializeRepository(workTreePath: workTreePath) }
    }

    func absoluteGitConfigFilePathAsync(workTreePath: String) async -> String? {
        await performOffMain { self.absoluteGitConfigFilePath(workTreePath: workTreePath) }
    }
}
