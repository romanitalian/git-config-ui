import Foundation

struct Alias: Identifiable {
    var id: String { key }
    var key: String    // e.g. "co"
    var value: String  // e.g. "checkout"
}
