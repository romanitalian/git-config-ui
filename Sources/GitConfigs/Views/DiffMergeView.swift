import SwiftUI

struct DiffMergeView: View {
    var body: some View {
        List {
            Section("Diff") {
                ScopedSettingRow(label: "Tool",     key: "diff.tool",    placeholder: "vimdiff")
                ScopedSettingRow(label: "GUI Tool", key: "diff.guitool", placeholder: "opendiff")
            }
            Section("Merge") {
                ScopedSettingRow(label: "Tool",           key: "merge.tool",          placeholder: "vimdiff")
                ScopedSettingRow(label: "Conflict Style", key: "merge.conflictstyle", placeholder: "merge")
            }
        }
    }
}
