import SwiftUI

struct AliasesView: View {
    @State private var aliases: [Alias] = []
    @State private var busyAliasKeys: Set<String> = []
    @State private var isReloading = false
    @State private var showEditor  = false
    @State private var editingAlias: Alias?

    private let service = GitConfigService.shared

    var body: some View {
        VStack(spacing: 0) {
            if aliases.isEmpty && !isReloading {
                emptyState
            } else {
                aliasList
            }

            Divider()

            HStack {
                Button {
                    editingAlias = nil
                    showEditor   = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Alias")
                .disabled(isReloading)

                Spacer()

                Button { reloadAsync() } label: {
                    if isReloading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .help("Refresh")
                .disabled(isReloading)
            }
            .padding(10)
        }
        .onAppear { reloadAsync() }
        .onChange(of: showEditor) { newValue in
            if newValue { NSApp.activate(ignoringOtherApps: true) }
        }
        .sheet(isPresented: $showEditor) {
            AliasEditor(alias: editingAlias) { saved in
                Task {
                    isReloading = true
                    if let old = editingAlias, old.key != saved.key {
                        await service.deleteAliasAsync(key: old.key)
                    }
                    await service.saveAliasAsync(saved)
                    await applyReloadFromGit()
                    isReloading = false
                }
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
                let isBusy = busyAliasKeys.contains(alias.key)
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
                        guard !isBusy else { return }
                        editingAlias = alias
                        showEditor   = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .controlSize(.small)
                    .disabled(isBusy)

                    Button {
                        deleteAlias(alias)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .controlSize(.small)
                    .disabled(isBusy)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .busyOverlay(isBusy)
                .accessibilityIdentifier("aliasRow-\(alias.key)")
                .accessibilityValue(isBusy ? "Loading" : "")
                .onTapGesture(count: 2) {
                    guard !isBusy else { return }
                    editingAlias = alias
                    showEditor   = true
                }
            }
        }
    }

    private func deleteAlias(_ alias: Alias) {
        guard !busyAliasKeys.contains(alias.key) else { return }
        busyAliasKeys.insert(alias.key)
        Task {
            await service.deleteAliasAsync(key: alias.key)
            busyAliasKeys.remove(alias.key)
            await applyReloadFromGit()
        }
    }

    private func reloadAsync() {
        guard !isReloading else { return }
        isReloading = true
        Task {
            await applyReloadFromGit()
            isReloading = false
        }
    }

    @MainActor
    private func applyReloadFromGit() async {
        aliases = await service.loadAliasesAsync()
    }
}
