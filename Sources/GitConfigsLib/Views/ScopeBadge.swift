import SwiftUI

struct ScopeBadge: View {
    let isLocal: Bool

    var body: some View {
        Text(isLocal ? "local ↑" : "global")
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(isLocal ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
            .foregroundColor(isLocal ? .accentColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
