import SwiftUI

enum SoloraOnboardingStep: Int, CaseIterable {
    case welcome
    case sources
    case personalization
    case learning
    case ready

    var progress: Double {
        Double(rawValue + 1) / Double(Self.allCases.count)
    }
}

enum SoloraOnboardingSource: String, CaseIterable, Hashable, Identifiable {
    case cv
    case chatGPT

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cv: "CV"
        case .chatGPT: "ChatGPT memories"
        }
    }

    var subtitle: String {
        switch self {
        case .cv: "Roles, projects and skills"
        case .chatGPT: "Copy a prompt, then review what comes back"
        }
    }

    var symbol: String {
        switch self {
        case .cv: "doc.text.fill"
        case .chatGPT: "bubble.left.and.bubble.right.fill"
        }
    }

    var tint: Color {
        switch self {
        case .cv: SoloraTheme.coral
        case .chatGPT: SoloraTheme.lavender
        }
    }
}

enum SoloraLearningPhase: Int, CaseIterable, Identifiable {
    case gathering
    case reading
    case connecting
    case forming
    case shaping

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .gathering: "Gathering the pieces"
        case .reading: "Reading your timeline"
        case .connecting: "Connecting projects and turning points"
        case .forming: "Forming your first Soloras"
        case .shaping: "Shaping a world that feels like you"
        }
    }

    var detail: String {
        switch self {
        case .gathering: "Bringing your chosen sources into one private space."
        case .reading: "Looking for the work, people and ideas that keep returning."
        case .connecting: "Finding the threads between what you did and what it meant."
        case .forming: "Turning useful moments into living pieces of your lore."
        case .shaping: "Giving those memories a form you can explore and reuse."
        }
    }

    var progress: Double {
        Double(rawValue + 1) / Double(Self.allCases.count)
    }

    var beatMilliseconds: Int {
        switch self {
        case .gathering: 650
        case .reading: 850
        case .connecting: 950
        case .forming: 950
        case .shaping: 1_050
        }
    }
}

struct SoloraOnboardingOrbSeed: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let depth: CGFloat
    let color: Color
    let phase: Double

    static let welcome: [Self] = [
        .init(id: 0, x: 0.04, y: 0.12, size: 58, depth: 0.82, color: SoloraTheme.lavender, phase: 0.15),
        .init(id: 1, x: 0.84, y: 0.08, size: 72, depth: 0.92, color: SoloraTheme.gold, phase: 0.72),
        .init(id: 2, x: 0.96, y: 0.38, size: 42, depth: 0.48, color: SoloraTheme.moss, phase: 1.26),
        .init(id: 3, x: 0.02, y: 0.46, size: 82, depth: 1.00, color: SoloraTheme.coral, phase: 1.82),
        .init(id: 4, x: 0.76, y: 0.72, size: 54, depth: 0.64, color: SoloraTheme.lavender, phase: 2.36),
        .init(id: 5, x: 0.28, y: 0.02, size: 34, depth: 0.34, color: SoloraTheme.gold, phase: 2.92),
        .init(id: 6, x: 0.14, y: 0.80, size: 46, depth: 0.58, color: SoloraTheme.moss, phase: 3.44),
        .init(id: 7, x: 0.94, y: 0.86, size: 76, depth: 0.96, color: SoloraTheme.coral, phase: 3.98),
        .init(id: 8, x: 0.56, y: -0.04, size: 24, depth: 0.20, color: SoloraTheme.cream, phase: 4.52),
        .init(id: 9, x: -0.04, y: 0.68, size: 30, depth: 0.28, color: SoloraTheme.gold, phase: 5.08),
        .init(id: 10, x: 0.68, y: 0.92, size: 38, depth: 0.42, color: SoloraTheme.plum, phase: 5.62),
        .init(id: 11, x: 1.02, y: 0.18, size: 28, depth: 0.24, color: SoloraTheme.lavender, phase: 6.08)
    ]
}
