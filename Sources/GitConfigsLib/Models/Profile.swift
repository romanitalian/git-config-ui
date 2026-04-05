import Foundation

struct Profile: Identifiable, Equatable {
    let id: String
    /// Legacy key in `~/.gitconfig`; kept in sync with `name` on save.
    var label: String
    var name: String
    var email: String
    var isLocal: Bool    = false
    var repoPath: String = ""   // required when isLocal == true

    /// Row title in the list (name is authoritative; label only for older saved data).
    var rowTitle: String {
        name.isEmpty ? label : name
    }

    init(id: String = UUID().uuidString,
         label: String = "",
         name: String = "",
         email: String = "",
         isLocal: Bool = false,
         repoPath: String = "") {
        self.id       = id
        self.label    = label
        self.name     = name
        self.email    = email
        self.isLocal  = isLocal
        self.repoPath = repoPath
    }
}
