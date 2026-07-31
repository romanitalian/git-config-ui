import SwiftUI

/// A self-contained settings row that reads/writes a single global git config key.
/// Shows inline Save/Cancel when the value has been edited.
struct ScopedSettingRow: View {
    let label: String
    let key: String
    let placeholder: String

    @State private var value   = ""
    @State private var isDirty = false
    @State private var isSaving = false
    @State private var isLoading = false

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
                .disabled(isSaving || isLoading)
                .onChange(of: value) { _ in isDirty = true }

            if isDirty {
                Button("Save") { saveAsync() }
                    .controlSize(.small)
                    .disabled(isSaving || isLoading)
                Button("Cancel") { reloadAsync() }
                    .controlSize(.small)
                    .disabled(isSaving)
            }

            if isSaving || isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
        .opacity(isSaving || isLoading ? 0.65 : 1)
        .onAppear { reloadAsync() }
    }

    private func reloadAsync() {
        guard !isLoading, !isSaving else { return }
        isLoading = true
        Task {
            let loaded = await service.readSettingAsync(key)
            value = loaded
            isDirty = false
            isLoading = false
        }
    }

    private func saveAsync() {
        guard !isSaving else { return }
        isSaving = true
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        Task {
            if trimmed.isEmpty {
                await service.unsetSettingAsync(key)
            } else {
                await service.writeSettingAsync(key, value: value)
            }
            let loaded = await service.readSettingAsync(key)
            value = loaded
            isDirty = false
            isSaving = false
        }
    }
}
