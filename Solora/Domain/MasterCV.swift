import Foundation

struct MasterCV: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let version: Int
    let contentMarkdown: String
    let structuredEntryCount: Int
    let formatProfile: CVFormatProfile
}

struct CVFormatProfile: Equatable, Sendable {
    let languageVariant: String
    let voice: String
    let dateStyle: String
    let sourceTypeface: String
    let sourcePageCount: Int
}

struct CVEntry: Equatable, Identifiable, Sendable {
    let id: String
    let type: String
    let title: String
    let dateLabel: String?
    let descriptor: String?
    let location: String?
    let bullets: [String]
    let orderWithinType: Int
}
