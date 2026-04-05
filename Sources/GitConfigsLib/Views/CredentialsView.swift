import SwiftUI

struct CredentialsView: View {
    var body: some View {
        List {
            ScopedSettingRow(label: "Helper",   key: "credential.helper",   placeholder: "osxkeychain")
            ScopedSettingRow(label: "Username", key: "credential.username", placeholder: "your-username")
        }
    }
}
