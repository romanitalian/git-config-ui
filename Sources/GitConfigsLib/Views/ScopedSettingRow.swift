import SwiftUI

/// A self-contained settings row that reads/writes a single global git config key.
/// Shows inline Save/Cancel when the value has been edited.
struct ScopedSettingRow: View {
    let label: String
    let key: String
    let placeholder: String

    @State private var value   = ""
    @State private var isDirty = false

    private let service = GitConfigService.shared

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .fontWeight(.medium)
                Text(key)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .frame(width: 130, alignment: .leading)

            TextField(placeholder, text: $value)
                .textFieldStyle(.roundedBorder)
                .onChange(of: value) { _ in isDirty = true }

            if isDirty {
                Button("Save")   { save()   }.controlSize(.small)
                Button("Cancel") { reload() }.controlSize(.small)
            }
        }
        .padding(.vertical, 2)
        .onAppear { reload() }
    }

    private func reload() {
        value   = service.readSetting(key)
        isDirty = false
    }

    private func save() {
        if value.trimmingCharacters(in: .whitespaces).isEmpty {
            service.unsetSetting(key)
        } else {
            service.writeSetting(key, value: value)
        }
        reload()
    }
}
