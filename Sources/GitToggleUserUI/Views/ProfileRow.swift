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
                    Text(profile.label)
                        .fontWeight(.medium)
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                Text("\(profile.name) <\(profile.email)>")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !isActive {
                Button("Activate") {
                    onActivate()
                }
                .controlSize(.small)
            }

            Button {
                onEdit()
            } label: {
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
                Text("Delete profile \"\(profile.label)\"?")
            }
        }
        .padding(.vertical, 4)
    }
}
