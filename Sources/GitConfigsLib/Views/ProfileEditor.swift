import SwiftUI
import AppKit

struct ProfileEditor: View {
    let profile: Profile?
    let existingProfiles: [Profile]
    let onSave: (Profile) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name:     String
    @State private var email:    String
    @State private var isLocal:  Bool
    @State private var repoPath: String
    /// Resolved `git rev-parse --git-path config` (or error text) for the Repo work tree.
    @State private var gitConfigFileDisplay: String = ""
    @State private var configFilePermissionLine: String = ""
    @State private var configFilePreviewText: String = ""
    @State private var initErrorMessage: String = ""
    @State private var isInitializing = false

    @FocusState private var focusedField: Field?

    private let profileId: String
    private let service = GitConfigService.shared

    private enum Field: Hashable {
        case name, email
    }

    private let fieldLabelWidth: CGFloat = 52

    init(profile: Profile?, existingProfiles: [Profile], onSave: @escaping (Profile) -> Void) {
        self.profile          = profile
        self.existingProfiles = existingProfiles
        self.onSave           = onSave
        self.profileId        = profile?.id ?? UUID().uuidString
        _name     = State(initialValue: profile?.name     ?? "")
        _email    = State(initialValue: profile?.email    ?? "")
        _isLocal  = State(initialValue: profile?.isLocal  ?? false)
        _repoPath = State(initialValue: profile?.repoPath ?? "")
    }

    /// Canonical absolute path so two local profiles cannot share the same repo directory.
    private static func normalizedAbsoluteRepoPath(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        let expanded = (trimmed as NSString).expandingTildeInPath
        var url = URL(fileURLWithPath: expanded, isDirectory: true)
        if FileManager.default.fileExists(atPath: url.path) {
            url = url.resolvingSymlinksInPath()
        }
        return (url.path as NSString).standardizingPath
    }

    /// Another local profile (not this one) already uses this repo path (after normalization).
    private var isDuplicateRepo: Bool {
        guard isLocal else { return false }
        let mine = Self.normalizedAbsoluteRepoPath(repoPath)
        guard !mine.isEmpty else { return false }
        return existingProfiles.contains { p in
            guard p.id != profileId, p.isLocal else { return false }
            let other = Self.normalizedAbsoluteRepoPath(p.repoPath)
            return !other.isEmpty && other == mine
        }
    }

    /// Local scope requires a real Git work tree (same check as resolved config path).
    private var hasValidGitRepo: Bool {
        guard isLocal else { return true }
        let n = Self.normalizedAbsoluteRepoPath(repoPath)
        guard !n.isEmpty else { return false }
        return service.absoluteGitConfigFilePath(workTreePath: n) != nil
    }

    private var isValid: Bool {
        !name.trimmed.isEmpty &&
        !email.trimmed.isEmpty &&
        (!isLocal || (!Self.normalizedAbsoluteRepoPath(repoPath).isEmpty && !isDuplicateRepo && hasValidGitRepo))
    }

    private var normalizedWorkTreePath: String {
        Self.normalizedAbsoluteRepoPath(repoPath)
    }

    private var canInitializeGitRepo: Bool {
        let path = normalizedWorkTreePath
        guard !path.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: path) && FileManager.default.isWritableFile(atPath: path)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(profile == nil ? "New Profile" : "Edit Profile")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 14) {
                GroupBox {
                    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 8, verticalSpacing: 10) {
                        GridRow {
                            Text("Name:")
                                .frame(width: fieldLabelWidth, alignment: .trailing)
                            TextField("", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .name)
                        }
                        GridRow {
                            Text("Email:")
                                .frame(width: fieldLabelWidth, alignment: .trailing)
                            TextField("", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .email)
                        }
                    }
                    .padding(8)
                } label: {
                    Text("Git user")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Scope")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Picker("", selection: $isLocal) {
                        Text("Global").tag(false)
                        Text("Local").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Global — applies to all repositories")
                        Text("• Local — applies only to the chosen repository")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                if isLocal {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Repository")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        pathPanel(
                            title: "Working tree",
                            subtitle: "Repository folder on disk",
                            highlightError: isDuplicateRepo
                        ) {
                            HStack(alignment: .top, spacing: 8) {
                                Text(repoPath.isEmpty ? "No folder selected" : repoPath)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(repoPath.isEmpty ? .secondary : (isDuplicateRepo ? .red : .primary))
                                    .lineLimit(3)
                                    .truncationMode(.head)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button("Choose…") { pickRepo() }
                                    .instantPress()
                                    .controlSize(.small)
                            }
                        }

                        if isDuplicateRepo {
                            Text("A local profile for this repository already exists.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        if !normalizedWorkTreePath.isEmpty && !isDuplicateRepo && !hasValidGitRepo {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Not a Git repository. Initialize the folder or choose another path.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                HStack(spacing: 10) {
                                    Button("Initialize repository") {
                                        runGitInit()
                                    }
                                    .instantPress()
                                    .disabled(!canInitializeGitRepo || isInitializing)
                                    .controlSize(.small)
                                    if isInitializing {
                                        ProgressView()
                                            .controlSize(.small)
                                            .scaleEffect(0.8)
                                    }
                                }
                                if !canInitializeGitRepo {
                                    Text("No write permission for this folder (or the path is not accessible).")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                if !initErrorMessage.isEmpty {
                                    Text(initErrorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        if !Self.normalizedAbsoluteRepoPath(repoPath).isEmpty {
                            pathPanel(
                                title: "Config file",
                                subtitle: "Local Git configuration for this repository"
                            ) {
                                Text(gitConfigFileDisplay.isEmpty ? "—" : gitConfigFileDisplay)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineLimit(4)
                                    .truncationMode(.head)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            if isLocal, !Self.normalizedAbsoluteRepoPath(repoPath).isEmpty {
                configFilePreviewBlock
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
            }

            Divider()
                .padding(.top, 12)

            HStack {
                Button("Cancel") { dismiss() }
                    .instantPress()
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    guard isValid else { return }
                    InstantFeedback.acknowledge()
                    let storedPath = isLocal ? Self.normalizedAbsoluteRepoPath(repoPath) : ""
                    let trimmedName = name.trimmed
                    let p = Profile(
                        id:       profileId,
                        label:    trimmedName,
                        name:     trimmedName,
                        email:    email.trimmed,
                        isLocal:  isLocal,
                        repoPath: storedPath
                    )
                    onSave(p)
                    dismiss()
                }
                .instantPress()
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding(16)
        }
        .frame(width: 440)
        .onAppear {
            focusedField = .name
            refreshGitConfigPath()
        }
        .onChange(of: repoPath) { _ in
            initErrorMessage = ""
            refreshGitConfigPath()
        }
        .onChange(of: isLocal) { _ in
            initErrorMessage = ""
            refreshGitConfigPath()
        }
    }

    private func runGitInit() {
        initErrorMessage = ""
        let path = normalizedWorkTreePath
        guard !path.isEmpty, !isInitializing else { return }
        InstantFeedback.acknowledge()
        isInitializing = true
        InstantFeedback.runAfterPaint {
            let err = await service.initializeRepositoryAsync(workTreePath: path)
            isInitializing = false
            if let err {
                initErrorMessage = err
            } else {
                refreshGitConfigPath()
            }
        }
    }

    @ViewBuilder
    private var configFilePreviewBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Config file on disk")
                .font(.subheadline)
                .fontWeight(.medium)
            if !configFilePermissionLine.isEmpty {
                Text(configFilePermissionLine)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ScrollView {
                Text(configFilePreviewText.isEmpty ? " " : configFilePreviewText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 72, maxHeight: 200)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
    }

    private func pathPanel<C: View>(
        title: String,
        subtitle: String,
        highlightError: Bool = false,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            content()
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(highlightError ? Color.red : Color(nsColor: .separatorColor), lineWidth: highlightError ? 1.5 : 1)
                )
        }
    }

    private func refreshGitConfigPath() {
        guard isLocal else {
            gitConfigFileDisplay = ""
            refreshConfigFilePreview()
            return
        }
        let normalized = Self.normalizedAbsoluteRepoPath(repoPath)
        guard !normalized.isEmpty else {
            gitConfigFileDisplay = ""
            refreshConfigFilePreview()
            return
        }
        if let path = service.absoluteGitConfigFilePath(workTreePath: normalized) {
            gitConfigFileDisplay = path
        } else {
            gitConfigFileDisplay = "Not a Git repository"
        }
        refreshConfigFilePreview()
    }

    private func refreshConfigFilePreview() {
        configFilePermissionLine = ""
        configFilePreviewText = ""

        guard isLocal else { return }
        let normalized = Self.normalizedAbsoluteRepoPath(repoPath)
        guard !normalized.isEmpty else { return }

        if gitConfigFileDisplay == "Not a Git repository" || gitConfigFileDisplay.isEmpty {
            configFilePreviewText =
                "Could not resolve a config file path — this folder is not a Git repository, or Git could not determine the repository directory."
            return
        }

        let path = gitConfigFileDisplay
        let fm = FileManager.default

        guard fm.fileExists(atPath: path) else {
            configFilePreviewText =
                "This file does not exist yet. There may be no Git repository at the working tree path, the repo is not initialized, or the path is unavailable."
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
            if fm.fileExists(atPath: parent) {
                let pr = fm.isReadableFile(atPath: parent)
                let pw = fm.isWritableFile(atPath: parent)
                configFilePermissionLine =
                    "Config file: missing · Parent directory — readable: \(pr ? "yes" : "no"), writable: \(pw ? "yes" : "no")"
            } else {
                configFilePermissionLine = "Config file: missing · Parent directory not accessible"
            }
            return
        }

        let readable = fm.isReadableFile(atPath: path)
        let writable = fm.isWritableFile(atPath: path)
        configFilePermissionLine =
            "Readable: \(readable ? "yes" : "no") · Writable: \(writable ? "yes" : "no")"

        guard readable else {
            configFilePreviewText = "No permission to read this file."
            return
        }

        do {
            let raw = try String(contentsOfFile: path, encoding: .utf8)
            configFilePreviewText = Self.truncatePreview(raw, limit: 48_000)
        } catch {
            configFilePreviewText = "Could not read file: \(error.localizedDescription)"
        }
    }

    private static func truncatePreview(_ s: String, limit: Int) -> String {
        guard s.count > limit else { return s }
        return String(s.prefix(limit)) + "\n\n… (truncated)"
    }

    private func pickRepo() {
        let panel = NSOpenPanel()
        panel.canChooseFiles          = false
        panel.canChooseDirectories    = true
        panel.allowsMultipleSelection = false
        panel.title                   = "Choose Git Repository"
        panel.prompt                  = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            repoPath = Self.normalizedAbsoluteRepoPath(url.path)
            refreshGitConfigPath()
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespaces) }
}
