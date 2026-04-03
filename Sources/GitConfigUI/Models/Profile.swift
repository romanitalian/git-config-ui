import Foundation

struct Profile: Identifiable, Equatable {
    let id: String
    var label: String
    var name: String
    var email: String

    init(id: String = UUID().uuidString, label: String = "", name: String = "", email: String = "") {
        self.id = id
        self.label = label
        self.name = name
        self.email = email
    }
}
