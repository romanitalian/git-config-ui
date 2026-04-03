import SwiftUI

struct DiffMergeView: View {
    @State private var diffTool: String = ""
    @State private var diffGuiTool: String = ""
    @State private var mergeTool: String = ""
    @State private var mergeConflictStyle: String = ""
    @State private var dirty = false

    private let service = GitConfigService.shared

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Diff") {
                    settingRow(label: "Tool",     key: "diff.tool",    placeholder: "vimdiff",  value: $diffTool)
                    settingRow(label: "GUI Tool", key: "diff.guitool", placeholder: "opendiff", value: $diffGuiTool)
                }
                Section("Merge") {
                    settingRow(label: "Tool",           key: "merge.tool",          placeholder: "vimdiff",    value: $mergeTool)
                    settingRow(label: "Conflict Style", key: "merge.conflictstyle", placeholder: "merge",      value: $mergeConflictStyle)
                }
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
        diffTool           = service.readSetting("diff.tool")
        diffGuiTool        = service.readSetting("diff.guitool")
        mergeTool          = service.readSetting("merge.tool")
        mergeConflictStyle = service.readSetting("merge.conflictstyle")
        dirty = false
    }

    private func saveAll() {
        save(key: "diff.tool",          value: diffTool)
        save(key: "diff.guitool",       value: diffGuiTool)
        save(key: "merge.tool",         value: mergeTool)
        save(key: "merge.conflictstyle",value: mergeConflictStyle)
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
