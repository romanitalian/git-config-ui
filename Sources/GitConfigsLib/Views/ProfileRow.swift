import SwiftUI

struct ProfileRow: View {
    let profile: Profile
    let isActive: Bool
    let isBusy: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private let setGlobalButtonWidth: CGFloat = 108

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
                Button(action: onActivate) {
                    ZStack {
                        Text("Set as Global")
                            .opacity(isBusy ? 0 : 1)
                        if isBusy {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .frame(width: setGlobalButtonWidth)
                }
                .controlSize(.small)
                .disabled(isBusy)
            } else {
                Color.clear
                    .frame(width: setGlobalButtonWidth, height: 1)
                    .accessibilityHidden(true)
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .controlSize(.small)
            .disabled(isBusy)

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
            }
            .controlSize(.small)
            .disabled(isBusy)
            .alert("Delete Profile", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { onDelete() }
            } message: {
                Text("Delete profile \"\(profile.rowTitle)\"?")
            }

            if isBusy && isActive {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .allowsHitTesting(!isBusy)
        .accessibilityIdentifier("profileRow-\(profile.id)")
        .accessibilityValue(isBusy ? "Loading" : "")
        .animation(nil, value: isActive)
        .animation(nil, value: isBusy)
        .onTapGesture(count: 2) {
            guard !isBusy else { return }
            onEdit()
        }
    }
}
