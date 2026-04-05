import Foundation

enum AppMetadata {
    /// Used when the executable has no Info.plist (e.g. `swift run`).
    private static let fallbackMarketingVersion = "1.0.0"

    /// Marketing version from `CFBundleShortVersionString`, or a stable fallback.
    static var marketingVersion: String {
        guard let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              !v.isEmpty
        else {
            return Self.fallbackMarketingVersion
        }
        return v
    }

    /// Display string for UI (e.g. status bar), always with a `v` prefix.
    static var versionLabel: String {
        let v = marketingVersion
        return v.hasPrefix("v") ? v : "v\(v)"
    }
}
