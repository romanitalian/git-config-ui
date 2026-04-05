import SwiftUI

struct ProfileRow: View {
    let profile: Profile
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(profile.rowTitle)
                        .fontWeight(.medium)
                    ScopeBadge(isLocal: profile.isLocal)
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                Text("\(profile.name) <\(profile.email)>")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if profile.isLocal && !profile.repoPath.isEmpty {
                    Text(profile.repoPath)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }

            Spacer()

            if !isActive {
                Button("Set as Global") { onActivate() }
                    .controlSize(.small)
            }

            Button { onEdit() } label: {
                Image(systemName: "pencil")
            }
            .controlSize(.small)

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
            }
            .controlSize(.small)
            .alert("Delete Profile", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { onDelete() }
            } message: {
                Text("Delete profile \"\(profile.rowTitle)\"?")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onEdit() }
    }
}
