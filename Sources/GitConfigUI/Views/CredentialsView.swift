import SwiftUI

struct CredentialsView: View {
    @State private var helper: String = ""
    @State private var username: String = ""
    @State private var dirty = false

    private let service = GitConfigService.shared

    var body: some View {
        VStack(spacing: 0) {
            List {
                settingRow(label: "Helper", key: "credential.helper",
                           placeholder: "osxkeychain", value: $helper)
                settingRow(label: "Username", key: "credential.username",
                           placeholder: "your-username", value: $username)
            }

            Divider()

            HStack {
                Spacer()
                Button("Save Changes") { saveAll() }
                    .disabled(!dirty)
                    .padding(10)
            }
        }
        .onAppear { reload() }
    }

    private func settingRow(label: String, key: String, placeholder: String, value: Binding<String>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .fontWeight(.medium)
                Text(key)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .frame(width: 130, alignment: .leading)

            TextField(placeholder, text: value)
                .textFieldStyle(.roundedBorder)
                .onChange(of: value.wrappedValue) { _ in dirty = true }
        }
        .padding(.vertical, 2)
    }

    private func reload() {
        helper   = service.readSetting("credential.helper")
        username = service.readSetting("credential.username")
        dirty = false
    }

    private func saveAll() {
        save(key: "credential.helper",   value: helper)
        save(key: "credential.username", value: username)
        dirty = false
    }

    private func save(key: String, value: String) {
        if value.trimmingCharacters(in: .whitespaces).isEmpty {
            service.unsetSetting(key)
        } else {
            service.writeSetting(key, value: value)
        }
    }
}
