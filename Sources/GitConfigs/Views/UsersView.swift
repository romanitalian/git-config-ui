import SwiftUI

struct UsersView: View {
    @State private var profiles: [Profile] = []
    @State private var activeProfileIds: Set<String> = []
    @State private var showEditor    = false
    @State private var editingProfile: Profile?
    /// Fresh SwiftUI identity per sheet open so ProfileEditor @State is not reused across sessions.
    @State private var editorSessionId = UUID()
    /// Bumped on each reload so the profile list re-renders from Git (global + local metadata).
    @State private var listRefreshID = UUID()

    private let service = GitConfigService.shared

    var body: some View {
        VStack(spacing: 0) {
            if profiles.isEmpty {
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

                Spacer()

                Button { reload() } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reload all profiles from Git configuration (global and local entries in this list)")
                .accessibilityLabel("Reload all profiles from Git configuration")
            }
            .padding(10)
        }
        .onAppear { reload() }
        .onChange(of: showEditor) { newValue in
            if newValue { NSApp.activate(ignoringOtherApps: true) }
        }
        .sheet(isPresented: $showEditor) {
            ProfileEditor(profile: editingProfile, existingProfiles: profiles) { saved in
                service.saveProfile(saved)
                if saved.isLocal {
                    service.activateProfile(saved)
                }
                DispatchQueue.main.async { reload() }
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
                    onActivate: {
                        service.activateProfile(profile)
                        reload()
                    },
                    onEdit: {
                        editingProfile = profile
                        editorSessionId = UUID()
                        showEditor     = true
                    },
                    onDelete: {
                        service.deleteProfile(profile)
                        reload()
                    }
                )
            }
        }
        .id(listRefreshID)
    }

    /// Re-reads all `gituserchange-profile.*` rows from Git and recomputes active checkmarks.
    private func reload() {
        let loaded = service.loadProfiles()
        profiles = loaded
        activeProfileIds = Set(loaded.filter { service.isProfileActive($0) }.map { $0.id })
        listRefreshID = UUID()
    }
}
