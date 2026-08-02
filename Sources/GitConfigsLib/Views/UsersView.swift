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
                    .debugBorder(UIDebug.list)
            }

            Divider()

            HStack {
                Button {
                    InstantFeedback.acknowledge()
                    editingProfile = nil
                    editorSessionId = UUID()
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .instantPress()
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
                .instantPress()
                .help("Reload all profiles from Git configuration (global and local entries in this list)")
                .accessibilityLabel("Reload all profiles from Git configuration")
                .disabled(isReloading)
            }
            .padding(10)
            .debugBorder(UIDebug.toolbar)
        }
        .onAppear { reloadAsync() }
        .onChange(of: showEditor) { newValue in
            if newValue { NSApp.activate(ignoringOtherApps: true) }
        }
        .sheet(isPresented: $showEditor) {
            ProfileEditor(profile: editingProfile, existingProfiles: profiles) { saved in
                // Dismiss-first (editor already dismissed) + optimistic list update.
                InstantFeedback.acknowledge()
                upsertProfile(saved)
                if saved.isLocal {
                    applyActiveStateAfterActivate(saved)
                }
                Task {
                    await service.saveProfileAsync(saved)
                    if saved.isLocal {
                        await service.activateProfileAsync(saved)
                    }
                    await applyReloadFromGit()
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

    private var globalProfiles: [Profile] { profiles.filter { !$0.isLocal } }
    private var localProfiles: [Profile] { profiles.filter { $0.isLocal } }

    private var profilesList: some View {
        List {
            if !globalProfiles.isEmpty {
                Section {
                    sectionColumnHeader()
                    ForEach(globalProfiles) { profile in
                        profileRow(for: profile)
                            .listRowInsets(ProfileTableLayout.rowInsets)
                    }
                } header: {
                    sectionTitle("Global")
                }
            }
            if !localProfiles.isEmpty {
                Section {
                    sectionColumnHeader()
                    ForEach(localProfiles) { profile in
                        profileRow(for: profile)
                            .listRowInsets(ProfileTableLayout.rowInsets)
                    }
                } header: {
                    sectionTitle("Local")
                }
            }
        }
        .listStyle(.plain)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .center)
            .textCase(nil)
    }

    private func sectionColumnHeader() -> some View {
        ProfileTableLayout.columns(
            active: { Text("Active") },
            name: { Text("Name") },
            email: { Text("Email") },
            repository: { Text("Repository") },
            actions: { Color.clear }
        )
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Column headers: Active, Name, Email, Repository")
        .debugBorder(UIDebug.header)
        .listRowInsets(ProfileTableLayout.rowInsets)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func profileRow(for profile: Profile) -> some View {
        ProfileRow(
            profile:    profile,
            isActive:   activeProfileIds.contains(profile.id),
            isBusy:     busyProfileIDs.contains(profile.id),
            onActivate: { activateProfile(profile) },
            onEdit: {
                InstantFeedback.acknowledge()
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

    /// Optimistic activate: checkmark moves immediately; git runs in background with rollback on failure.
    private func activateProfile(_ profile: Profile) {
        let id = profile.id
        guard !busyProfileIDs.contains(id) else { return }
        InstantFeedback.acknowledge()
        let previousActive = activeProfileIds
        applyActiveStateAfterActivate(profile)
        Task {
            await service.activateProfileAsync(profile)
            let ok = await service.isProfileActiveAsync(profile)
            await MainActor.run {
                if !ok {
                    activeProfileIds = previousActive
                }
            }
        }
    }

    private func withBusyProfile(_ id: String, _ body: @escaping () async -> Void) {
        guard !busyProfileIDs.contains(id) else { return }
        InstantFeedback.acknowledge()
        busyProfileIDs.insert(id)
        InstantFeedback.runAfterPaint {
            await body()
            await applyReloadFromGit()
            busyProfileIDs.remove(id)
        }
    }

    @MainActor
    private func upsertProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
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
        InstantFeedback.acknowledge()
        isReloading = true
        InstantFeedback.runAfterPaint {
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
