import SwiftUI

enum ProfileTableLayout {
    static let spacing: CGFloat = 10
    static let globalWidth: CGFloat = 44
    static let actionsWidth: CGFloat = 64
    static let rowInsets = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)

    /// Shared column grid so header and data rows stay aligned.
    static func columns<Global: View, Name: View, Email: View, Repo: View, Actions: View>(
        @ViewBuilder global: () -> Global,
        @ViewBuilder name: () -> Name,
        @ViewBuilder email: () -> Email,
        @ViewBuilder repository: () -> Repo,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        HStack(spacing: spacing) {
            global()
                .frame(width: globalWidth, alignment: .center)
            name()
                .frame(maxWidth: .infinity, alignment: .leading)
            email()
                .frame(maxWidth: .infinity, alignment: .leading)
            repository()
                .frame(maxWidth: .infinity, alignment: .leading)
            actions()
                .frame(width: actionsWidth, alignment: .trailing)
        }
    }
}
