import Foundation

enum WorldKind: String, Codable, CaseIterable, Equatable, Sendable {
    case memoryShelves

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: value) ?? .memoryShelves
    }
}
