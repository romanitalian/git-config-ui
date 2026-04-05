import SwiftUI

private struct SettingDef: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let placeholder: String
}

private let knownSettings: [SettingDef] = [
    SettingDef(key: "core.editor",        label: "Editor",         placeholder: "vim"),
    SettingDef(key: "core.pager",         label: "Pager",          placeholder: "less"),
    SettingDef(key: "core.autocrlf",      label: "Auto CRLF",      placeholder: "false"),
    SettingDef(key: "init.defaultBranch", label: "Default Branch", placeholder: "main"),
    SettingDef(key: "push.default",       label: "Push Default",   placeholder: "simple"),
    SettingDef(key: "pull.rebase",        label: "Pull Rebase",    placeholder: "false"),
]

struct CoreSettingsView: View {
    var body: some View {
        List {
            ForEach(knownSettings) { row in
                ScopedSettingRow(label: row.label, key: row.key, placeholder: row.placeholder)
            }
        }
    }
}
