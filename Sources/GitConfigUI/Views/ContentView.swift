import SwiftUI

struct ContentView: View {
    @State private var currentName = ""
    @State private var currentEmail = ""
    @State private var profiles: [Profile] = []
    @State private var showEditor = false
    @State private var editingProfile: Profile?

    private let service = GitConfigService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Current user header
            currentUserSection
            Divider()

            // Profiles list
            if profiles.isEmpty {
                emptyState
            } else {
                profilesList
            }

            Divider()

            // Bottom toolbar
            HStack {
                Button {
                    editingProfile = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Profile")

                Spacer()

                Button {
                    reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
            .padding(10)
        }
        .frame(minWidth: 380, idealWidth: 400, minHeight: 350, idealHeight: 500)
        .onAppear { reload() }
        .onChange(of: showEditor) { newValue in
            if newValue { NSApp.activate(ignoringOtherApps: true) }
        }
        .sheet(isPresented: $showEditor) {
            ProfileEditor(profile: editingProfile) { saved in
                service.saveProfile(saved)
                reload()
            }
        }
    }

    // MARK: - Subviews

    private var currentUserSection: some View {
        VStack(spacing: 4) {
            Label("Current Git User", systemImage: "person.circle")
                .font(.headline)
            Text(currentName)
                .font(.body)
            Text(currentEmail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
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
                    profile: profile,
                    isActive: profile.name == currentName && profile.email == currentEmail,
                    onActivate: {
                        service.activateProfile(profile)
                        reload()
                    },
                    onEdit: {
                        editingProfile = profile
                        showEditor = true
                    },
                    onDelete: {
                        service.deleteProfile(profile)
                        reload()
                    }
                )
            }
        }
    }

    // MARK: - Helpers

    private func reload() {
        let user = service.loadCurrentUser()
        currentName = user.name
        currentEmail = user.email
        profiles = service.loadProfiles()
    }
}
