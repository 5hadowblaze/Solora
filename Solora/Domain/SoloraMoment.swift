import Foundation

struct SoloraMoment: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let date: Date
    let world: WorldKind
}
