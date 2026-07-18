import SwiftUI

struct WorldView: View {
    let manifest: WorldManifest

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: WorldRecommendation = .memoryShelves
    @State private var arrangementVersion = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    recommendationPicker

                    ZStack {
                        switch selection {
                        case .memoryShelves:
                            MemoryShelvesWorld(arrangementVersion: arrangementVersion)
                                .transition(worldTransition)
                        case .careerFridge:
                            CareerFridgeWorld()
                                .transition(worldTransition)
                        case .questMap:
                            QuestMapWorld()
                                .transition(worldTransition)
                        }
                    }
                    .animation(reduceMotion ? nil : .snappy(duration: 0.24), value: selection)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(SoloraTheme.cream)
            .navigationTitle("World")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your adaptive world")
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(SoloraTheme.ink)
            Text(manifest.subtitle)
                .font(.body)
                .foregroundStyle(SoloraTheme.ink.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private var recommendationPicker: some View {
        HStack(spacing: 0) {
            ForEach(WorldRecommendation.allCases) { recommendation in
                Button {
                    selection = recommendation
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: recommendation.symbol)
                            .font(.system(size: 15, weight: .semibold))
                        Text(recommendation.shortTitle)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selection == recommendation ? SoloraTheme.cream : SoloraTheme.ink)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background {
                        if selection == recommendation {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SoloraTheme.ink)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(recommendation.title)")
                .accessibilityHint(selection == recommendation ? "Currently selected" : "Switches the world layout")
                .accessibilityAddTraits(selection == recommendation ? .isSelected : [])
            }
        }
        .padding(4)
        .background(SoloraTheme.ink.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var worldTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97))
    }
}

private enum WorldRecommendation: String, CaseIterable, Identifiable {
    case memoryShelves, careerFridge, questMap

    var id: Self { self }
    var title: String {
        switch self {
        case .memoryShelves: "Memory Shelves"
        case .careerFridge: "Career Fridge"
        case .questMap: "Quest Map"
        }
    }
    var shortTitle: String {
        switch self {
        case .memoryShelves: "Shelves"
        case .careerFridge: "Fridge"
        case .questMap: "Map"
        }
    }
    var symbol: String {
        switch self {
        case .memoryShelves: "books.vertical.fill"
        case .careerFridge: "refrigerator.fill"
        case .questMap: "point.topleft.down.curvedto.point.bottomright.up"
        }
    }
}

private struct MemoryShelvesWorld: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let arrangementVersion: Int

    private let memories = [
        ShelfMemory(title: "Found clarity", skill: "Strategy", color: SoloraTheme.gold, size: 86),
        ShelfMemory(title: "Made the first move", skill: "Courage", color: SoloraTheme.coral, size: 70),
        ShelfMemory(title: "Aligned the room", skill: "Facilitation", color: SoloraTheme.lavender, size: 92),
        ShelfMemory(title: "Built the bridge", skill: "Relationships", color: SoloraTheme.gold, size: 74),
        ShelfMemory(title: "Shipped the brief", skill: "Craft", color: SoloraTheme.coral, size: 82)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Memory Shelves")
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(SoloraTheme.ink)
                Text("AI arranged from your archive")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SoloraTheme.coral)
                Text("Your brightest evidence, gathered into a world you can return to.")
                    .font(.subheadline)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.72))
            }

            shelfStage

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Arrangement \(arrangementVersion)")
                        .font(.footnote.weight(.bold))
                    Text("A fresh take on the same memories")
                        .font(.caption)
                        .foregroundStyle(SoloraTheme.ink.opacity(0.65))
                }
                Spacer(minLength: 8)
                Button {
                    arrangementVersion = arrangementVersion == 3 ? 1 : arrangementVersion + 1
                } label: {
                    Label("Regenerate world", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SoloraTheme.cream)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 46)
                        .background(SoloraTheme.coral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Changes the arrangement version for this demo. No network is used.")
            }
            .foregroundStyle(SoloraTheme.ink)
            .padding(.top, 2)
        }
        .accessibilityElement(children: .contain)
    }

    private var shelfStage: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(SoloraTheme.ink)

                // A quiet warm glow gives the stage depth; the memory orbs stay the focal point.
                Circle()
                    .fill(SoloraTheme.coral.opacity(0.24))
                    .frame(width: width * 0.72)
                    .blur(radius: 34)
                    .offset(x: width * 0.37, y: -90)

                VStack(alignment: .leading, spacing: 49) {
                    shelfRow([memories[0], memories[1]], offset: arrangementVersion == 2 ? 10 : 0)
                    shelfRow([memories[2], memories[3], memories[4]], offset: arrangementVersion == 3 ? 14 : 0)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
        .frame(height: 368)
        .accessibilityLabel("Memory shelves, arrangement \(arrangementVersion)")
        .accessibilityHint("Five labeled memory orbs are displayed on warm wooden shelves")
    }

    private func shelfRow(_ items: [ShelfMemory], offset: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            Capsule()
                .fill(SoloraTheme.gold.opacity(0.78))
                .frame(height: 13)
                .overlay(alignment: .bottom) { Capsule().fill(SoloraTheme.coral.opacity(0.55)).frame(height: 4) }

            HStack(alignment: .bottom, spacing: 9) {
                ForEach(items) { memory in
                    VStack(spacing: 5) {
                        SoloraOrbView(size: memory.size, color: memory.color)
                            .shadow(color: memory.color.opacity(0.4), radius: 14, y: 5)
                        Text(memory.title)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(SoloraTheme.cream)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(width: memory.size + 12)
                        Text(memory.skill)
                            .font(.caption2)
                            .foregroundStyle(memory.color.opacity(0.95))
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(memory.title), \(memory.skill) memory")
                    .accessibilityHint("An archived moment arranged by Solora")
                }
            }
            .offset(x: offset, y: -6)
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.24), value: arrangementVersion)
    }
}

private struct ShelfMemory: Identifiable {
    let title: String
    let skill: String
    let color: Color
    let size: CGFloat
    var id: String { title }
}

private struct CareerFridgeWorld: View {
    private let tiles = [("You advocated", "Leadership"), ("Workshop win", "Facilitation"), ("Kind follow-up", "Relationships"), ("Portfolio spark", "Craft")]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Career Fridge")
                .font(.system(.title, design: .serif, weight: .bold))
            Text("The small proof you keep close.")
                .foregroundStyle(SoloraTheme.ink.opacity(0.7))
            VStack(spacing: 12) {
                ForEach(tiles, id: \.0) { tile in
                    HStack(spacing: 14) {
                        Circle().fill(SoloraTheme.gold).frame(width: 18, height: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tile.0).font(.headline)
                            Text(tile.1).font(.caption.weight(.bold)).foregroundStyle(SoloraTheme.coral)
                        }
                        Spacer()
                    }
                    .padding(15)
                    .background(SoloraTheme.cream, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .rotationEffect(.degrees(tile.0 == "Workshop win" ? -2 : 1))
                }
            }
            .padding(18)
            .background(SoloraTheme.coral, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .foregroundStyle(SoloraTheme.ink)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Career Fridge with four magnet memories")
    }
}

private struct QuestMapWorld: View {
    private let stops = [("Curiosity", "Asked a sharper question"), ("Momentum", "Started the conversation"), ("Mastery", "Turned insight into craft")]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quest Map")
                .font(.system(.title, design: .serif, weight: .bold))
            Text("A career journey with your next brave move in view.")
                .foregroundStyle(SoloraTheme.ink.opacity(0.7))
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 0) {
                            Circle().fill(index == 2 ? SoloraTheme.coral : SoloraTheme.lavender).frame(width: 28, height: 28)
                                .overlay { Text("\(index + 1)").font(.caption.bold()).foregroundStyle(SoloraTheme.cream) }
                            if index < stops.count - 1 { Rectangle().fill(SoloraTheme.gold).frame(width: 3, height: 50) }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stop.0).font(.headline)
                            Text(stop.1).font(.subheadline).foregroundStyle(SoloraTheme.ink.opacity(0.7))
                        }
                        .padding(.top, 3)
                    }
                }
            }
            .padding(20)
            .background(SoloraTheme.cream, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(SoloraTheme.gold.opacity(0.72), lineWidth: 2) }
        }
        .foregroundStyle(SoloraTheme.ink)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quest map with three career journey nodes")
    }
}
