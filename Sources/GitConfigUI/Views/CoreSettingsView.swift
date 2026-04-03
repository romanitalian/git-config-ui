import SwiftUI

private struct SettingRow: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let placeholder: String
}

private let knownSettings: [SettingRow] = [
    SettingRow(key: "core.editor",       label: "Editor",          placeholder: "vim"),
    SettingRow(key: "core.pager",        label: "Pager",           placeholder: "less"),
    SettingRow(key: "core.autocrlf",     label: "Auto CRLF",       placeholder: "false"),
    SettingRow(key: "init.defaultBranch",label: "Default Branch",  placeholder: "main"),
    SettingRow(key: "push.default",      label: "Push Default",    placeholder: "simple"),
    SettingRow(key: "pull.rebase",       label: "Pull Rebase",     placeholder: "false"),
]

struct CoreSettingsView: View {
    @State private var values: [String: String] = [:]
    @State private var dirty: Set<String> = []

    private let service = GitConfigService.shared

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(knownSettings) { row in
                    settingRow(row)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Save Changes") { saveAll() }
                    .disabled(dirty.isEmpty)
                    .padding(10)
            }
        }
        .onAppear { reload() }
    }

    private func settingRow(_ row: SettingRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.label)
                    .fontWeight(.medium)
                Text(row.key)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .frame(width: 130, alignment: .leading)

            TextField(row.placeholder, text: binding(for: row.key))
                .textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 2)
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { values[key] ?? "" },
            set: { values[key] = $0; dirty.insert(key) }
        )
    }

    private func reload() {
        for row in knownSettings {
            values[row.key] = service.readSetting(row.key)
        }
        dirty.removeAll()
    }

    private func saveAll() {
        for key in dirty {
            let val = values[key] ?? ""
            if val.trimmingCharacters(in: .whitespaces).isEmpty {
                service.unsetSetting(key)
            } else {
                service.writeSetting(key, value: val)
            }
        }
        dirty.removeAll()
    }
}
