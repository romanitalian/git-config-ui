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
            active: { activeControl },
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
        .debugBorder(UIDebug.row)
        .contentShape(Rectangle())
        .allowsHitTesting(!isBusy)
        .accessibilityIdentifier("profileRow-\(profile.id)")
        .accessibilityValue(isBusy ? "Loading" : (isActive ? "Active" : ""))
        .accessibilityAction(named: "Edit") {
            guard !isBusy else { return }
            onEdit()
        }
        .animation(nil, value: isActive)
        .animation(nil, value: isBusy)
        .onTapGesture(count: 2) {
            guard !isBusy else { return }
            onEdit()
        }
    }

    @ViewBuilder
    private var activeControl: some View {
        if isBusy {
            ProgressView()
                .controlSize(.small)
        } else {
            Button(action: {
                guard !isActive else { return }
                onActivate()
            }) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                    .frame(width: ProfileTableLayout.activeWidth, height: 20)
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
                .help(profile.repoPath)
        } else {
            Text("—")
                .foregroundColor(.secondary)
        }
    }

    private var actions: some View {
        HStack(spacing: ProfileTableLayout.actionSpacing) {
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .frame(width: ProfileTableLayout.actionHitSize, height: ProfileTableLayout.actionHitSize)
                    .contentShape(Rectangle())
                    .debugBorder(UIDebug.actionButton)
            }
            .buttonStyle(.plain)
            .instantPress()
            .disabled(isBusy)
            .help("Edit")
            .accessibilityLabel("Edit")

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .frame(width: ProfileTableLayout.actionHitSize, height: ProfileTableLayout.actionHitSize)
                    .contentShape(Rectangle())
                    .debugBorder(UIDebug.actionButton)
            }
            .buttonStyle(.plain)
            .instantPress()
            .disabled(isBusy)
            .help("Delete")
            .accessibilityLabel("Delete")
            .alert("Delete Profile", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { onDelete() }
            } message: {
                Text("Delete profile \"\(profile.rowTitle)\"?")
            }
        }
    }
}
