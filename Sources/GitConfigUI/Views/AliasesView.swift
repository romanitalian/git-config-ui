import SwiftUI

struct AliasesView: View {
    @State private var aliases: [Alias] = []
    @State private var showEditor = false
    @State private var editingAlias: Alias?

    private let service = GitConfigService.shared

    var body: some View {
        VStack(spacing: 0) {
            if aliases.isEmpty {
                emptyState
            } else {
                aliasList
            }

            Divider()

            HStack {
                Button {
                    editingAlias = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Alias")

                Spacer()

                Button { reload() } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
            .padding(10)
        }
        .onAppear { reload() }
        .onChange(of: showEditor) { newValue in
            if newValue { NSApp.activate(ignoringOtherApps: true) }
        }
        .sheet(isPresented: $showEditor) {
            AliasEditor(alias: editingAlias) { saved in
                service.saveAlias(saved)
                reload()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "terminal")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No aliases configured")
                .foregroundColor(.secondary)
            Text("Click + to add a git alias")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var aliasList: some View {
        List {
            ForEach(aliases) { alias in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("git \(alias.key)")
                            .fontWeight(.medium)
                            .font(.system(.body, design: .monospaced))
                        Text(alias.value)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        editingAlias = alias
                        showEditor = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .controlSize(.small)

                    Button {
                        service.deleteAlias(key: alias.key)
                        reload()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .controlSize(.small)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func reload() {
        aliases = service.loadAliases()
    }
}
