import Foundation

struct SoloraMoment: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let date: Date
    let world: WorldKind
    let category: String?
    let stickerPath: String?
    let photoPaths: [String]

    var bubblePhotoPath: String? { photoPaths.first }
    var bubbleStickerPath: String? { stickerPath }

    init(
        id: String,
        title: String,
        summary: String,
        date: Date,
        world: WorldKind,
        category: String? = nil,
        stickerPath: String? = nil,
        photoPaths: [String] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.date = date
        self.world = world
        self.category = category
        self.stickerPath = stickerPath
        self.photoPaths = photoPaths
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        date = try container.decode(Date.self, forKey: .date)
        world = try container.decode(WorldKind.self, forKey: .world)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        stickerPath = try container.decodeIfPresent(String.self, forKey: .stickerPath)
        photoPaths = try container.decodeIfPresent([String].self, forKey: .photoPaths) ?? []
    }
}
