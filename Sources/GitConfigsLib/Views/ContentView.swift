import SwiftUI

public struct ContentView: View {
    @State private var selectedSection: AppSection? = .users

    public init() {}

    public var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                sidebarLogo
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .accessibilityLabel("GitConfigs logo")

                Divider()

                List(AppSection.allCases, selection: $selectedSection) { section in
                    Label(section.rawValue, systemImage: section.icon)
                        .tag(section)
                        .accessibilityIdentifier("sidebarSection-\(section.id)")
                }
                .listStyle(.sidebar)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            switch selectedSection {
            case .users, nil:  UsersView()
            case .aliases:     AliasesView()
            case .core:        CoreSettingsView()
            case .credentials: CredentialsView()
            case .diffMerge:   DiffMergeView()
            case .about:       AboutView()
            }
        }
    }

    @ViewBuilder
    private var sidebarLogo: some View {
        ZStack {
            if let nsImage = BrandLogo.nsImage() {
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.high)
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
