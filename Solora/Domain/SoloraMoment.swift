import Foundation

enum MemoryCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case personal
    case work
    case event
    case education
    case travel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .personal: "Personal"
        case .work: "Work & projects"
        case .event: "Events"
        case .education: "Education & growth"
        case .travel: "Travel & places"
        }
    }

    static func suggest(for reflection: String) -> Self {
        let value = reflection.lowercased()
        if value.contains("course") || value.contains("school") || value.contains("university") || value.contains("learn") { return .education }
        if value.contains("flight") || value.contains("trip") || value.contains("travel") || value.contains("hotel") { return .travel }
        if value.contains("family") || value.contains("friend") || value.contains("birthday") || value.contains("home") { return .personal }
        if value.contains("project") || value.contains("work") || value.contains("client") || value.contains("launch") || value.contains("team") { return .work }
        return .event
    }
}

enum MemoryPlaybackStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case photoSequence
    case livingSequence

    var id: String { rawValue }
    var title: String { self == .photoSequence ? "Photo sequence" : "Living sequence" }
}

struct MomentVisualAsset: Codable, Equatable, Identifiable, Sendable {
    enum Kind: String, Codable, Sendable { case photo, livePhoto }

    let id: String
    let posterPath: String
    let motionPath: String?
    let kind: Kind

    init(id: String = UUID().uuidString, posterPath: String, motionPath: String? = nil, kind: Kind = .photo) {
        self.id = id
        self.posterPath = posterPath
        self.motionPath = motionPath
        self.kind = kind
    }
}

struct SoloraMoment: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let reflection: String
    let date: Date
    let world: WorldKind
    let category: String?
    let memoryType: MemoryCategory
    let playbackStyle: MemoryPlaybackStyle
    let visualAssets: [MomentVisualAsset]
    let stickerPath: String?
    let photoPaths: [String]

    var bubblePhotoPath: String? { visualAssets.first?.posterPath ?? photoPaths.first }
    var bubbleStickerPath: String? { stickerPath }

    init(
        id: String,
        title: String,
        summary: String,
        reflection: String? = nil,
        date: Date,
        world: WorldKind,
        category: String? = nil,
        memoryType: MemoryCategory? = nil,
        playbackStyle: MemoryPlaybackStyle = .photoSequence,
        visualAssets: [MomentVisualAsset] = [],
        stickerPath: String? = nil,
        photoPaths: [String] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.reflection = reflection ?? summary
        self.date = date
        self.world = world
        self.category = category
        self.memoryType = memoryType ?? MemoryCategory.suggest(for: "\(category ?? "") \(reflection ?? summary)")
        self.playbackStyle = playbackStyle
        self.visualAssets = visualAssets.isEmpty
            ? photoPaths.map { MomentVisualAsset(posterPath: $0) }
            : visualAssets
        self.stickerPath = stickerPath
        self.photoPaths = photoPaths.isEmpty ? self.visualAssets.map(\.posterPath) : photoPaths
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        reflection = try container.decodeIfPresent(String.self, forKey: .reflection) ?? summary
        date = try container.decode(Date.self, forKey: .date)
        world = try container.decode(WorldKind.self, forKey: .world)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        memoryType = try container.decodeIfPresent(MemoryCategory.self, forKey: .memoryType)
            ?? MemoryCategory.suggest(for: "\(category ?? "") \(reflection)")
        playbackStyle = try container.decodeIfPresent(MemoryPlaybackStyle.self, forKey: .playbackStyle) ?? .photoSequence
        photoPaths = try container.decodeIfPresent([String].self, forKey: .photoPaths) ?? []
        visualAssets = try container.decodeIfPresent([MomentVisualAsset].self, forKey: .visualAssets)
            ?? photoPaths.map { MomentVisualAsset(posterPath: $0) }
        stickerPath = try container.decodeIfPresent(String.self, forKey: .stickerPath)
    }
}
