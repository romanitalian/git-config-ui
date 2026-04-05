import SwiftUI

struct AboutView: View {
    private let repositoryURL = URL(string: "https://github.com/romanitalian/git-config-ui")!

    var body: some View {
        Form {
            Section {
                Text(
                    "GitConfigs edits your global Git identity and common settings through "
                        + "/usr/bin/git. Data stays in your ~/.gitconfig on this Mac."
                )
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("About")
            }

            Section {
                LabeledContent("Version") {
                    Text(AppMetadata.versionLabel)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }

            Section {
                Link(destination: repositoryURL) {
                    Label("View on GitHub", systemImage: "link")
                }
            } header: {
                Text("Source")
            }

            Section {
                Text("Copyright © \(calendarYear) GitConfigs contributors.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("GitConfigs")
    }

    private var calendarYear: Int {
        Calendar.current.component(.year, from: Date())
    }
}
