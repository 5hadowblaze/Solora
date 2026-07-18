import SwiftUI

struct WorldView: View {
    let manifest: WorldManifest
    let moments: [SoloraMoment]
    let vibe: String
    let visualReference: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var memoryNamespace
    @GestureState private var liveDrag: CGSize = .zero

    @State private var skin: LoreSkin
    @State private var arrangement = 0
    @State private var selectedID: String?
    @State private var expandedID: String?
    @State private var settledDrag: CGSize = .zero
    @State private var showsArchive = false

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
        _skin = State(initialValue: LoreSkin.initial(for: visualReference))
        _selectedID = State(initialValue: moments.first?.id)
    }

    private var displayedMoments: [SoloraMoment] {
        Array(moments.prefix(6))
    }

    private var selectedMoment: SoloraMoment? {
        displayedMoments.first { $0.id == selectedID } ?? displayedMoments.first
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    skin.background.ignoresSafeArea()

                    LoreCanvas(
                        moments: displayedMoments,
                        skin: skin,
                        arrangement: arrangement,
                        selectedID: $selectedID,
                        expandedID: expandedID,
                        namespace: memoryNamespace,
                        parallax: combinedDrag,
                        reduceMotion: reduceMotion
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .contentShape(Rectangle())
                    .gesture(stageDrag)

                    VStack(spacing: 0) {
                        topBar
                        Spacer()
                        memoryDock
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                    if let expandedID,
                       let moment = displayedMoments.first(where: { $0.id == expandedID }) {
                        MemoryDetail(
                            moment: moment,
                            color: color(for: moment),
                            namespace: memoryNamespace,
                            onClose: closeDetail
                        )
                        .transition(reduceMotion ? .opacity : .soloraReveal)
                        .zIndex(10)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showsArchive) {
                ArchiveView(moments: moments)
            }
            .sensoryFeedback(.selection, trigger: selectedID)
            .sensoryFeedback(.selection, trigger: skin)
            .sensoryFeedback(.impact(weight: .light), trigger: arrangement)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Your lore")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                Text(skin.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(skin.foreground.opacity(0.58))
                    .contentTransition(.interpolate)
            }

            Spacer()

            Menu {
                ForEach(LoreSkin.allCases) { option in
                    Button {
                        withAnimation(reduceMotion ? nil : SoloraMotion.spatial) {
                            skin = option
                            settledDrag = .zero
                        }
                    } label: {
                        Label(option.title, systemImage: option.symbol)
                    }
                }
            } label: {
                Image(systemName: "paintpalette.fill")
                    .symbolEffect(.bounce, value: skin)
                    .frame(width: 44, height: 44)
                    .background(skin.controlFill, in: Circle())
            }
            .buttonStyle(SoloraPressButtonStyle())
            .accessibilityLabel("World style: \(skin.title)")

            Button { showsArchive = true } label: {
                Image(systemName: "rectangle.stack.fill")
                    .frame(width: 44, height: 44)
                    .background(skin.controlFill, in: Circle())
            }
            .buttonStyle(SoloraPressButtonStyle())
            .accessibilityLabel("Open archive list")
        }
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(skin.foreground)
    }

    private var memoryDock: some View {
        VStack(spacing: 10) {
            if let moment = selectedMoment {
                Button {
                    openDetail(moment)
                } label: {
                    HStack(spacing: 13) {
                        SoloraOrbView(
                            size: 42,
                            color: color(for: moment),
                            mediaPath: moment.bubblePhotoPath,
                            stickerPath: moment.bubbleStickerPath
                        )
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(moment.title)
                                .font(.subheadline.weight(.bold))
                                .lineLimit(1)
                            Text(moment.date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption.weight(.medium))
                                .opacity(0.56)
                        }

                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(skin.dockForeground)
                    .padding(.horizontal, 14)
                    .frame(height: 68)
                    .background(skin.dockFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .soloraHairline(skin.dockStroke, radius: 14)
                }
                .buttonStyle(SoloraPressButtonStyle(pressedScale: 0.985))
                .id(moment.id)
                .transition(reduceMotion ? .opacity : .soloraReveal)
            }

            HStack {
                Label("Drag the room", systemImage: "hand.draw.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(skin.foreground.opacity(0.50))

                Spacer()

                Button {
                    withAnimation(reduceMotion ? nil : SoloraMotion.spatial) {
                        arrangement = (arrangement + 1) % 3
                        settledDrag = .zero
                    }
                } label: {
                    Label("Recompose", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(skin.foreground)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(skin.controlFill, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(SoloraPressButtonStyle())
                .accessibilityHint("Rearranges the same memories")
            }
        }
    }

    private var combinedDrag: CGSize {
        reduceMotion ? .zero : CGSize(
            width: settledDrag.width + liveDrag.width * 0.34,
            height: settledDrag.height + liveDrag.height * 0.20
        )
    }

    private var stageDrag: some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($liveDrag) { value, state, _ in state = value.translation }
            .onEnded { value in
                guard !reduceMotion else { return }
                let proposed = CGSize(
                    width: settledDrag.width + value.predictedEndTranslation.width * 0.16,
                    height: settledDrag.height + value.predictedEndTranslation.height * 0.10
                )
                withAnimation(SoloraMotion.spatial) {
                    settledDrag = CGSize(
                        width: min(26, max(-26, proposed.width)),
                        height: min(18, max(-18, proposed.height))
                    )
                }
            }
    }

    private func openDetail(_ moment: SoloraMoment) {
        withAnimation(reduceMotion ? .easeOut(duration: 0.18) : SoloraMotion.spatial) {
            selectedID = moment.id
            expandedID = moment.id
        }
    }

    private func closeDetail() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.spatial) {
            expandedID = nil
        }
    }

    private func color(for moment: SoloraMoment) -> Color {
        let index = displayedMoments.firstIndex(where: { $0.id == moment.id }) ?? 0
        return SoloraTheme.orbColors[index % SoloraTheme.orbColors.count]
    }
}

private enum LoreSkin: String, CaseIterable, Identifiable {
    case coreRoom
    case constellation
    case fridge

    var id: Self { self }

    var title: String {
        switch self {
        case .coreRoom: "Core room"
        case .constellation: "Constellation"
        case .fridge: "Career fridge"
        }
    }

    var symbol: String {
        switch self {
        case .coreRoom: "circle.grid.3x3.fill"
        case .constellation: "point.3.connected.trianglepath.dotted"
        case .fridge: "refrigerator.fill"
        }
    }

    var background: Color {
        switch self {
        case .coreRoom: SoloraTheme.ink
        case .constellation: SoloraTheme.plum
        case .fridge: SoloraTheme.coral
        }
    }

    var foreground: Color { skinIsLight ? SoloraTheme.ink : SoloraTheme.cream }
    var controlFill: Color { skinIsLight ? SoloraTheme.ink.opacity(0.08) : SoloraTheme.cream.opacity(0.10) }
    var dockFill: Color { skinIsLight ? SoloraTheme.cream.opacity(0.92) : SoloraTheme.cream.opacity(0.94) }
    var dockForeground: Color { SoloraTheme.ink }
    var dockStroke: Color { skinIsLight ? SoloraTheme.ink.opacity(0.15) : Color.white.opacity(0.20) }
    private var skinIsLight: Bool { self == .fridge }

    static func initial(for visualReference: String) -> Self {
        let lowered = visualReference.lowercased()
        if lowered.contains("fridge") || lowered.contains("magnet") { return .fridge }
        if lowered.contains("map") { return .constellation }
        return .coreRoom
    }
}

private struct LoreCanvas: View {
    let moments: [SoloraMoment]
    let skin: LoreSkin
    let arrangement: Int
    @Binding var selectedID: String?
    let expandedID: String?
    let namespace: Namespace.ID
    let parallax: CGSize
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let points = layoutPoints(in: proxy.size)

            ZStack {
                decoration(points: points, size: proxy.size)

                ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                    memoryOrb(moment, index: index)
                        .position(points[index % points.count])
                        .offset(
                            x: parallax.width * depth(for: index),
                            y: parallax.height * depth(for: index)
                        )
                        .zIndex(selectedID == moment.id ? 3 : 1)
                }
            }
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : Double(parallax.width / 18)),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.42
            )
            .animation(reduceMotion ? nil : SoloraMotion.spatial, value: arrangement)
            .animation(reduceMotion ? nil : SoloraMotion.spatial, value: skin)
        }
        .accessibilityElement(children: .contain)
    }

    private func memoryOrb(_ moment: SoloraMoment, index: Int) -> some View {
        let isSelected = selectedID == moment.id
        let isExpanded = expandedID == moment.id
        let size = [82.0, 64.0, 74.0, 58.0, 70.0, 62.0][index % 6]
        let color = SoloraTheme.orbColors[index % SoloraTheme.orbColors.count]

        return Button {
            withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
                selectedID = moment.id
            }
        } label: {
            VStack(spacing: 7) {
                SoloraOrbView(
                    size: size,
                    color: color,
                    isAlive: isSelected && !isExpanded,
                    showsHalo: isSelected,
                    mediaPath: moment.bubblePhotoPath,
                    stickerPath: moment.bubbleStickerPath
                )
                .matchedGeometryEffect(id: "orb-\(moment.id)", in: namespace, isSource: !isExpanded)
                .opacity(isExpanded ? 0 : 1)

                if isSelected && !isExpanded {
                    Text(moment.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(skin.foreground)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 112)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(SoloraPressButtonStyle(pressedScale: 0.94))
        .accessibilityLabel(moment.title)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityHint("Selects this memory")
    }

    @ViewBuilder
    private func decoration(points: [CGPoint], size: CGSize) -> some View {
        switch skin {
        case .coreRoom:
            ZStack {
                Circle()
                    .fill(SoloraTheme.coral.opacity(0.24))
                    .frame(width: size.width * 0.95)
                    .blur(radius: 56)
                    .offset(x: size.width * 0.34, y: -size.height * 0.15)

                VStack(spacing: size.height * 0.23) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(SoloraTheme.gold.opacity(0.72))
                            .frame(width: size.width * 0.88, height: 9)
                            .overlay(alignment: .bottom) {
                                Capsule().fill(SoloraTheme.coral.opacity(0.60)).frame(height: 3)
                            }
                            .shadow(color: .black.opacity(0.32), radius: 8, y: 7)
                    }
                }
                .offset(y: size.height * 0.08)
            }

        case .constellation:
            Canvas { context, _ in
                var path = Path()
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [SoloraTheme.gold.opacity(0.28), SoloraTheme.cream.opacity(0.5)]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [3, 8])
                )
            }

        case .fridge:
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SoloraTheme.cream.opacity(0.18))
                .padding(.horizontal, 10)
                .padding(.vertical, 84)
                .overlay {
                    Rectangle()
                        .fill(SoloraTheme.ink.opacity(0.18))
                        .frame(width: 2)
                        .offset(x: size.width * 0.32)
                }
        }
    }

    private func layoutPoints(in size: CGSize) -> [CGPoint] {
        let normalized: [CGPoint]
        switch skin {
        case .coreRoom:
            normalized = [
                CGPoint(x: 0.23, y: 0.25), CGPoint(x: 0.69, y: 0.22),
                CGPoint(x: 0.38, y: 0.49), CGPoint(x: 0.77, y: 0.52),
                CGPoint(x: 0.21, y: 0.73), CGPoint(x: 0.63, y: 0.75)
            ]
        case .constellation:
            normalized = [
                CGPoint(x: 0.22, y: 0.22), CGPoint(x: 0.66, y: 0.18),
                CGPoint(x: 0.49, y: 0.40), CGPoint(x: 0.76, y: 0.60),
                CGPoint(x: 0.29, y: 0.66), CGPoint(x: 0.58, y: 0.79)
            ]
        case .fridge:
            normalized = [
                CGPoint(x: 0.22, y: 0.26), CGPoint(x: 0.63, y: 0.22),
                CGPoint(x: 0.38, y: 0.47), CGPoint(x: 0.76, y: 0.53),
                CGPoint(x: 0.20, y: 0.70), CGPoint(x: 0.59, y: 0.75)
            ]
        }

        let reordered: [CGPoint]
        switch arrangement % 3 {
        case 1: reordered = Array(normalized.dropFirst(2)) + Array(normalized.prefix(2))
        case 2: reordered = Array(normalized.reversed())
        default: reordered = normalized
        }

        return reordered.map { point in
            CGPoint(x: point.x * size.width, y: point.y * size.height)
        }
    }

    private func depth(for index: Int) -> CGFloat {
        [0.30, 0.52, 0.40, 0.70, 0.46, 0.62][index % 6]
    }
}

private struct MemoryDetail: View {
    let moment: SoloraMoment
    let color: Color
    let namespace: Namespace.ID
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            SoloraTheme.cream.ignoresSafeArea()

            Circle()
                .fill(color.opacity(0.34))
                .frame(width: 420, height: 420)
                .blur(radius: 34)
                .offset(x: 170, y: -300)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(moment.date.formatted(.dateTime.day().month(.wide).year()))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.50))
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(SoloraTheme.ink)
                            .frame(width: 44, height: 44)
                            .background(SoloraTheme.ink.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(SoloraPressButtonStyle())
                    .accessibilityLabel("Close memory")
                }

                Spacer(minLength: 20)

                HStack {
                    Spacer()
                    SoloraOrbView(
                        size: 190,
                        color: color,
                        isAlive: true,
                        showsHalo: true,
                        mediaPath: moment.bubblePhotoPath,
                        stickerPath: moment.bubbleStickerPath
                    )
                        .matchedGeometryEffect(id: "orb-\(moment.id)", in: namespace, isSource: false)
                    Spacer()
                }

                Spacer(minLength: 28)

                Text(moment.title)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .tracking(-1.1)
                    .fixedSize(horizontal: false, vertical: true)

                Text(moment.summary)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.66))
                    .padding(.top, 12)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .overlay(SoloraTheme.ink.opacity(0.14))
                    .padding(.vertical, 22)

                HStack(spacing: 24) {
                    detailLabel("Proof", value: "Saved")
                    detailLabel("Thread", value: thread)
                    detailLabel("Source", value: "Calendar")
                }

                Spacer(minLength: 18)

                Button {
                    onClose()
                } label: {
                    HStack {
                        Text("Use in Share")
                        Spacer()
                        Image(systemName: "wand.and.rays")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SoloraTheme.cream)
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(SoloraPressButtonStyle())
            }
            .foregroundStyle(SoloraTheme.ink)
            .padding(20)
        }
        .accessibilityElement(children: .contain)
    }

    private var thread: String {
        let title = moment.title.lowercased()
        if title.contains("room") || title.contains("bridge") { return "People" }
        if title.contains("brief") || title.contains("clarity") { return "Craft" }
        return "Momentum"
    }

    private func detailLabel(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(SoloraTheme.ink.opacity(0.48))
            Text(value)
                .font(.subheadline.weight(.bold))
        }
    }
}
