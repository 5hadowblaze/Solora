import SwiftUI

struct WorldView: View {
    let manifest: WorldManifest
    let moments: [SoloraMoment]
    let vibe: String
    let visualReference: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: WorldRecommendation
    @State private var arrangementVersion = 1

    init(
        manifest: WorldManifest,
        moments: [SoloraMoment] = DemoFixtures.moments,
        vibe: String = "thoughtful",
        visualReference: String = "Inside Out orbs"
    ) {
        self.manifest = manifest
        self.moments = moments
        self.vibe = vibe
        self.visualReference = visualReference
        _selection = State(initialValue: WorldRecommendation.initial(for: visualReference))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    recommendationPicker

                    ZStack {
                        switch selection {
                        case .memoryShelves:
                            MemoryShelvesWorld(arrangementVersion: $arrangementVersion, moments: moments)
                                .transition(worldTransition)
                        case .careerFridge:
                            CareerFridgeWorld(moments: moments)
                                .transition(worldTransition)
                        case .questMap:
                            QuestMapWorld(moments: moments)
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
            Text("Designed for your \(vibe) vibe")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SoloraTheme.coral)
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

    static func initial(for visualReference: String) -> Self {
        let reference = visualReference.lowercased()
        if reference.contains("career fridge") || reference.contains("magnet") { return .careerFridge }
        if reference.contains("quest map") || reference.contains("map") { return .questMap }
        return .memoryShelves
    }
}

private struct MemoryShelvesWorld: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var arrangementVersion: Int
    let moments: [SoloraMoment]

    private var memories: [ShelfMemory] {
        let source = Array((moments.isEmpty ? DemoFixtures.moments : moments).prefix(5))
        let ordered: [SoloraMoment]
        switch arrangementVersion {
        case 2: ordered = source.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case 3: ordered = Array(source.reversed())
        default: ordered = source
        }
        return ordered.enumerated().map { index, moment in
            ShelfMemory(
                id: moment.id,
                title: moment.title,
                summary: moment.summary,
                skill: shelfLabel(for: moment, index: index),
                color: [SoloraTheme.gold, SoloraTheme.coral, SoloraTheme.lavender][index % 3],
                size: [82, 70, 90, 76, 84][index % 5]
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Memory Shelves")
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(SoloraTheme.ink)
                Text(arrangementDescription)
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
                    Text(arrangementDescription)
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
                .accessibilityHint("Reinterprets the same saved moments with a different grouping. No network is used.")
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
                    shelfRow(Array(memories.prefix(firstShelfCount)), offset: arrangementVersion == 2 ? 10 : 0)
                    shelfRow(Array(memories.dropFirst(firstShelfCount)), offset: arrangementVersion == 3 ? 14 : 0)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
        .frame(height: 368)
        .accessibilityLabel("Memory shelves, arrangement \(arrangementVersion)")
        .accessibilityHint("Saved moments appear as labeled memory orbs on warm wooden shelves")
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
                        Text(memory.summary)
                            .font(.caption2)
                            .foregroundStyle(memory.color.opacity(0.95))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(width: memory.size + 12)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(memory.title), \(memory.summary). \(memory.skill) memory")
                    .accessibilityHint("An archived moment arranged by Solora")
                }
            }
            .offset(x: offset, y: -6)
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.24), value: arrangementVersion)
    }

    private var firstShelfCount: Int {
        guard memories.count > 1 else { return memories.count }
        return min(2, memories.count)
    }

    private var arrangementDescription: String {
        switch arrangementVersion {
        case 2: "Alphabetized by the stories you named"
        case 3: "Newest perspective, with the latest moments first"
        default: "Your saved evidence, grouped by momentum"
        }
    }

    private func shelfLabel(for moment: SoloraMoment, index: Int) -> String {
        let words = moment.summary.split(separator: " ")
        return words.first.map(String.init) ?? ["Momentum", "Courage", "Craft"][index % 3]
    }
}

private struct ShelfMemory: Identifiable {
    let id: String
    let title: String
    let summary: String
    let skill: String
    let color: Color
    let size: CGFloat
}

private struct CareerFridgeWorld: View {
    let moments: [SoloraMoment]

    private var tiles: [(id: String, title: String, skill: String)] {
        let source = moments.isEmpty ? DemoFixtures.moments : moments
        return source.prefix(4).enumerated().map { index, moment in
            (moment.id, moment.title, ["Momentum", "Proof", "Connection", "Craft"][index % 4])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Career Fridge")
                .font(.system(.title, design: .serif, weight: .bold))
            Text("The small proof you keep close.")
                .foregroundStyle(SoloraTheme.ink.opacity(0.7))
            VStack(spacing: 12) {
                ForEach(tiles, id: \.id) { tile in
                    HStack(spacing: 14) {
                        Circle().fill(SoloraTheme.gold).frame(width: 18, height: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tile.title).font(.headline)
                            Text(tile.skill).font(.caption.weight(.bold)).foregroundStyle(SoloraTheme.coral)
                        }
                        Spacer()
                    }
                    .padding(15)
                    .background(SoloraTheme.cream, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .rotationEffect(.degrees(tile.id.hashValue.isMultiple(of: 2) ? -2 : 1))
                }
            }
            .padding(18)
            .background(SoloraTheme.coral, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .foregroundStyle(SoloraTheme.ink)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Career Fridge with saved-moment magnets")
    }
}

private struct QuestMapWorld: View {
    let moments: [SoloraMoment]

    private var stops: [(String, String)] {
        let source = moments.isEmpty ? DemoFixtures.moments : moments
        return source.prefix(3).enumerated().map { index, moment in
            (["Curiosity", "Momentum", "Mastery"][index], moment.title)
        }
    }

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
        .accessibilityLabel("Quest map with saved-moment career journey nodes")
    }
}
