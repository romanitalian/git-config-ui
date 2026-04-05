import SwiftUI

public struct ContentView: View {
    @State private var selectedSection: AppSection? = .users

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("GitConfigs")
        } detail: {
            switch selectedSection {
            case .users, nil:  UsersView()
            case .aliases:     AliasesView()
            case .core:        CoreSettingsView()
            case .credentials: CredentialsView()
            case .diffMerge:   DiffMergeView()
            }
        }
    }
}
