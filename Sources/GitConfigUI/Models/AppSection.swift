import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case users       = "Users"
    case aliases     = "Aliases"
    case core        = "Core Settings"
    case credentials = "Credentials"
    case diffMerge   = "Diff & Merge"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .users:       return "person.2"
        case .aliases:     return "terminal"
        case .core:        return "gearshape"
        case .credentials: return "key"
        case .diffMerge:   return "arrow.triangle.branch"
        }
    }
}
