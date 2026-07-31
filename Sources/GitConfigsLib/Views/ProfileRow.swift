import SwiftUI

struct ProfileRow: View {
    let profile: Profile
    let isActive: Bool
    let isBusy: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        ProfileTableLayout.columns(
            global: { globalCheckbox },
            name: {
                Text(profile.rowTitle)
                    .fontWeight(.medium)
                    .lineLimit(1)
            },
            email: {
                Text(profile.email)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            },
            repository: { repositoryCell },
            actions: { actions }
        )
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .allowsHitTesting(!isBusy)
        .accessibilityIdentifier("profileRow-\(profile.id)")
        .accessibilityValue(isBusy ? "Loading" : (isActive ? "Active" : ""))
        .animation(nil, value: isActive)
        .animation(nil, value: isBusy)
        .onTapGesture(count: 2) {
            guard !isBusy else { return }
            onEdit()
        }
    }

    @ViewBuilder
    private var globalCheckbox: some View {
        if isBusy {
            ProgressView()
                .controlSize(.small)
        } else {
            Button(action: {
                guard !isActive else { return }
                onActivate()
            }) {
                Image(systemName: isActive ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14))
                    .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                    .frame(width: ProfileTableLayout.globalWidth, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .instantPress()
            .disabled(isActive)
            .help(profile.isLocal ? "Activate for this repository" : "Set as Global")
            .accessibilityLabel(profile.isLocal ? "Set as Local" : "Set as Global")
            .accessibilityAddTraits(isActive ? .isSelected : [])
        }
    }

    @ViewBuilder
    private var repositoryCell: some View {
        if profile.isLocal && !profile.repoPath.isEmpty {
            Text(profile.repoPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.head)
        } else {
            Text("—")
                .foregroundColor(.secondary)
        }
    }

    private var actions: some View {
        HStack(spacing: 4) {
            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .instantPress()
            .controlSize(.small)
            .disabled(isBusy)

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
            }
            .instantPress()
            .controlSize(.small)
            .disabled(isBusy)
            .alert("Delete Profile", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { onDelete() }
            } message: {
                Text("Delete profile \"\(profile.rowTitle)\"?")
            }
        }
    }
}
