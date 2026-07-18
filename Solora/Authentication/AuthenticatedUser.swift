import Foundation

struct AuthenticatedUser: Equatable, Sendable {
    let id: String
    let displayName: String
    let email: String?
    let photoURL: URL?

    var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    var initials: String {
        let words = displayName.split(separator: " ").prefix(2)
        let value = words.compactMap(\.first).map(String.init).joined()
        return value.isEmpty ? "S" : value.uppercased()
    }

    static let demo = AuthenticatedUser(
        id: "demo-user",
        displayName: "Amir",
        email: nil,
        photoURL: nil
    )
}
