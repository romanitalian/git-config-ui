import SwiftUI

struct UsersView: View {
    @State private var profiles: [Profile] = []
    @State private var activeProfileIds: Set<String> = []
    @State private var busyProfileIDs: Set<String> = []
    @State private var isReloading = false
    @State private var showEditor    = false
    @State private var editingProfile: Profile?
    /// Fresh SwiftUI identity per sheet open so ProfileEditor @State is not reused across sessions.
    @State private var editorSessionId = UUID()

    private let service = GitConfigService.shared

    var body: some View {
        VStack(spacing: 0) {
            if profiles.isEmpty && !isReloading {
                emptyState
            } else {
                profilesList
            }

            Divider()

            HStack {
                Button {
                    editingProfile = nil
                    editorSessionId = UUID()
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Profile")
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
                .help("Reload all profiles from Git configuration (global and local entries in this list)")
                .accessibilityLabel("Reload all profiles from Git configuration")
                .disabled(isReloading)
            }
            .padding(10)
        }
        .onAppear { reloadAsync() }
        .onChange(of: showEditor) { newValue in
            if newValue { NSApp.activate(ignoringOtherApps: true) }
        }
        .sheet(isPresented: $showEditor) {
            ProfileEditor(profile: editingProfile, existingProfiles: profiles) { saved in
                Task {
                    isReloading = true
                    await service.saveProfileAsync(saved)
                    if saved.isLocal {
                        await service.activateProfileAsync(saved)
                    }
                    await applyReloadFromGit()
                    isReloading = false
                }
            }
            .id(editorSessionId)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No profiles yet")
                .foregroundColor(.secondary)
            Text("Click + to add a profile")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var profilesList: some View {
        List {
            ForEach(profiles) { profile in
                ProfileRow(
                    profile:    profile,
                    isActive:   activeProfileIds.contains(profile.id),
                    isBusy:     busyProfileIDs.contains(profile.id),
                    onActivate: { activateProfile(profile) },
                    onEdit: {
                        editingProfile = profile
                        editorSessionId = UUID()
                        showEditor     = true
                    },
                    onDelete: {
                        withBusyProfile(profile.id) {
                            await service.deleteProfileAsync(profile)
                        }
                    }
                )
            }
        }
    }

    private func activateProfile(_ profile: Profile) {
        let id = profile.id
        guard !busyProfileIDs.contains(id) else { return }
        busyProfileIDs.insert(id)
        Task {
            await service.activateProfileAsync(profile)
            await MainActor.run {
                applyActiveStateAfterActivate(profile)
                busyProfileIDs.remove(id)
            }
        }
    }

    private func withBusyProfile(_ id: String, _ body: @escaping () async -> Void) {
        guard !busyProfileIDs.contains(id) else { return }
        busyProfileIDs.insert(id)
        Task {
            await body()
            await applyReloadFromGit()
            busyProfileIDs.remove(id)
        }
    }

    /// Updates checkmarks after activate without reloading the whole list (avoids a busy→idle→active double blink).
    @MainActor
    private func applyActiveStateAfterActivate(_ profile: Profile) {
        var next = activeProfileIds
        if profile.isLocal {
            next.insert(profile.id)
        } else {
            for p in profiles where !p.isLocal {
                next.remove(p.id)
            }
            next.insert(profile.id)
        }
        activeProfileIds = next
    }

    private func reloadAsync() {
        guard !isReloading else { return }
        isReloading = true
        Task {
            await applyReloadFromGit()
            isReloading = false
        }
    }

    /// Re-reads all `gituserchange-profile.*` rows from Git and recomputes active checkmarks.
    @MainActor
    private func applyReloadFromGit() async {
        let loaded = await service.loadProfilesAsync()
        profiles = loaded
        var active = Set<String>()
        for profile in loaded where await service.isProfileActiveAsync(profile) {
            active.insert(profile.id)
        }
        activeProfileIds = active
    }
}
