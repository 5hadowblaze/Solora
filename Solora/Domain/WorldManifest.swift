import Foundation

struct WorldManifest: Codable, Equatable, Sendable {
    let kind: WorldKind
    let title: String
    let subtitle: String
    let shelves: [String]
}
