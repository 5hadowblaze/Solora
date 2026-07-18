import SwiftUI

struct WorldView: View {
    let manifest: WorldManifest
    let moments: [SoloraMoment]
    let vibe: String
    let visualReference: String
    let focusMemoryID: String?

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
        visualReference: String = "Inside Out orbs",
        focusMemoryID: String? = nil
    ) {
        self.manifest = manifest
        self.moments = moments
        self.vibe = vibe
        self.visualReference = visualReference
        self.focusMemoryID = focusMemoryID
        _skin = State(initialValue: LoreSkin.initial(for: visualReference))
        _selectedID = State(initialValue: moments.first?.id)
    }

    private var displayedMoments: [SoloraMoment] {
        var displayed = Array(moments.prefix(6))
        if let focusMemoryID,
           let focused = moments.first(where: { $0.id == focusMemoryID }),
           !displayed.contains(where: { $0.id == focused.id }) {
            displayed = [focused] + displayed.dropLast()
        }
        return displayed
    }

    private var selectedMoment: SoloraMoment? {
        displayedMoments.first { $0.id == selectedID } ?? displayedMoments.first
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    LoreBackdrop(
                        skin: skin,
                        parallax: combinedDrag,
                        reduceMotion: reduceMotion
                    )

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
            .onChange(of: focusMemoryID, initial: true) { _, identifier in
                guard let identifier,
                      let moment = displayedMoments.first(where: { $0.id == identifier }) else { return }
                openDetail(moment)
            }
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

private struct LoreBackdrop: View {
    let skin: LoreSkin
    let parallax: CGSize
    let reduceMotion: Bool

    var body: some View {
        Group {
            switch skin {
            case .coreRoom:
                CoreMindBackdrop(parallax: parallax)
            case .constellation:
                NightSkyBackdrop(parallax: parallax)
            case .fridge:
                CareerFridgeBackdrop(parallax: parallax)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .animation(reduceMotion ? nil : SoloraMotion.spatial, value: skin)
    }
}

private struct CoreMindBackdrop: View {
    let parallax: CGSize

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.05, blue: 0.18),
                        Color(red: 0.24, green: 0.08, blue: 0.25),
                        Color(red: 0.09, green: 0.12, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color(red: 1.00, green: 0.35, blue: 0.43).opacity(0.72))
                    .frame(width: size.width * 1.05)
                    .blur(radius: 76)
                    .offset(
                        x: size.width * 0.42 + parallax.width * 0.12,
                        y: -size.height * 0.25 + parallax.height * 0.12
                    )

                Circle()
                    .fill(Color(red: 0.99, green: 0.70, blue: 0.22).opacity(0.58))
                    .frame(width: size.width * 0.72)
                    .blur(radius: 68)
                    .offset(
                        x: -size.width * 0.37 + parallax.width * 0.20,
                        y: size.height * 0.29 + parallax.height * 0.20
                    )

                Circle()
                    .fill(Color(red: 0.28, green: 0.78, blue: 0.86).opacity(0.40))
                    .frame(width: size.width * 0.86)
                    .blur(radius: 82)
                    .offset(
                        x: size.width * 0.28 + parallax.width * 0.28,
                        y: size.height * 0.42 + parallax.height * 0.28
                    )

                Circle()
                    .fill(SoloraTheme.lavender.opacity(0.46))
                    .frame(width: size.width * 0.58)
                    .blur(radius: 54)
                    .offset(
                        x: -size.width * 0.32 + parallax.width * 0.34,
                        y: -size.height * 0.08 + parallax.height * 0.34
                    )

                CoreEnergyField(size: size)
                    .offset(x: parallax.width * 0.16, y: parallax.height * 0.16)

                Ellipse()
                    .stroke(
                        AngularGradient(
                            colors: [
                                .clear,
                                SoloraTheme.gold.opacity(0.46),
                                Color.white.opacity(0.16),
                                .clear
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size.width * 1.08, height: size.height * 0.34)
                    .rotationEffect(.degrees(-14))
                    .offset(x: parallax.width * 0.42, y: parallax.height * 0.42)
                    .blur(radius: 0.4)

                LinearGradient(
                    colors: [.clear, Color(red: 0.03, green: 0.03, blue: 0.10).opacity(0.48)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }
}

private struct CoreEnergyField: View {
    let size: CGSize

    var body: some View {
        Canvas { context, canvasSize in
            for index in 0..<18 {
                let x = CGFloat((index * 47 + 13) % 101) / 100 * canvasSize.width
                let y = CGFloat((index * 71 + 29) % 103) / 102 * canvasSize.height
                let diameter = CGFloat(2 + (index % 4))
                let color = index.isMultiple(of: 3) ? SoloraTheme.gold : Color.white
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                    with: .color(color.opacity(index.isMultiple(of: 2) ? 0.42 : 0.22))
                )
            }

            for index in 0..<3 {
                let inset = CGFloat(index) * 42
                var path = Path()
                path.move(to: CGPoint(x: -30, y: canvasSize.height * (0.28 + CGFloat(index) * 0.20)))
                path.addCurve(
                    to: CGPoint(x: canvasSize.width + 30, y: canvasSize.height * (0.42 + CGFloat(index) * 0.14)),
                    control1: CGPoint(x: canvasSize.width * 0.30, y: inset),
                    control2: CGPoint(x: canvasSize.width * 0.68, y: canvasSize.height - inset)
                )
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            .clear,
                            SoloraTheme.coral.opacity(0.22),
                            SoloraTheme.gold.opacity(0.34),
                            .clear
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
                    ),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                )
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct NightSkyBackdrop: View {
    let parallax: CGSize

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.015, green: 0.025, blue: 0.095),
                        Color(red: 0.055, green: 0.045, blue: 0.18),
                        Color(red: 0.015, green: 0.02, blue: 0.07)
                    ],
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color(red: 0.24, green: 0.20, blue: 0.62).opacity(0.34))
                    .frame(width: size.width * 1.18)
                    .blur(radius: 92)
                    .offset(x: -size.width * 0.38, y: -size.height * 0.06)

                Circle()
                    .fill(Color(red: 0.16, green: 0.54, blue: 0.72).opacity(0.18))
                    .frame(width: size.width * 0.92)
                    .blur(radius: 82)
                    .offset(x: size.width * 0.38, y: size.height * 0.30)

                StarField(count: 78, near: false)
                    .offset(x: parallax.width * 0.08, y: parallax.height * 0.08)

                planet(size: size.width * 0.24)
                    .position(x: size.width * 0.86, y: size.height * 0.23)
                    .offset(x: parallax.width * 0.22, y: parallax.height * 0.22)

                moon(size: size.width * 0.11)
                    .position(x: size.width * 0.13, y: size.height * 0.57)
                    .offset(x: parallax.width * 0.34, y: parallax.height * 0.34)

                StarField(count: 34, near: true)
                    .offset(x: parallax.width * 0.46, y: parallax.height * 0.46)

                RadialGradient(
                    colors: [.clear, Color.black.opacity(0.56)],
                    center: .center,
                    startRadius: min(size.width, size.height) * 0.20,
                    endRadius: max(size.width, size.height) * 0.72
                )
                .allowsHitTesting(false)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    private func planet(size: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .stroke(Color(red: 0.76, green: 0.73, blue: 1.0).opacity(0.32), lineWidth: 2)
                .frame(width: size * 1.72, height: size * 0.42)
                .rotationEffect(.degrees(-18))

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.88, green: 0.66, blue: 0.78),
                            Color(red: 0.38, green: 0.28, blue: 0.64),
                            Color(red: 0.08, green: 0.08, blue: 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                }
                .shadow(color: Color(red: 0.56, green: 0.46, blue: 1).opacity(0.30), radius: 24)
                .frame(width: size, height: size)
        }
        .frame(width: size * 1.8, height: size * 1.2)
    }

    private func moon(size: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [SoloraTheme.cream, SoloraTheme.gold.opacity(0.72)],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: size
                )
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: size * 0.24)
                    .offset(x: -size * 0.16, y: size * 0.18)
            }
            .shadow(color: SoloraTheme.cream.opacity(0.32), radius: 18)
            .frame(width: size, height: size)
    }
}

private struct StarField: View {
    let count: Int
    let near: Bool

    var body: some View {
        Canvas { context, size in
            for index in 0..<count {
                let x = CGFloat((index * 67 + (near ? 19 : 7)) % 101) / 100 * size.width
                let y = CGFloat((index * 43 + (near ? 31 : 11)) % 103) / 102 * size.height
                let diameter = near ? CGFloat(1.3 + Double(index % 4) * 0.7) : CGFloat(0.7 + Double(index % 3) * 0.45)
                let opacity = near ? 0.42 + Double(index % 3) * 0.16 : 0.20 + Double(index % 4) * 0.10
                let tint = index.isMultiple(of: 7) ? SoloraTheme.gold : Color.white
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                    with: .color(tint.opacity(opacity))
                )

                if near && index.isMultiple(of: 11) {
                    var flare = Path()
                    flare.move(to: CGPoint(x: x - 4, y: y + diameter / 2))
                    flare.addLine(to: CGPoint(x: x + diameter + 4, y: y + diameter / 2))
                    flare.move(to: CGPoint(x: x + diameter / 2, y: y - 4))
                    flare.addLine(to: CGPoint(x: x + diameter / 2, y: y + diameter + 4))
                    context.stroke(flare, with: .color(Color.white.opacity(0.32)), lineWidth: 0.7)
                }
            }
        }
    }
}

private struct CareerFridgeBackdrop: View {
    let parallax: CGSize

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.31, green: 0.22, blue: 0.28),
                        Color(red: 0.74, green: 0.32, blue: 0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.94, green: 0.95, blue: 0.93),
                                Color(red: 0.77, green: 0.83, blue: 0.83),
                                Color(red: 0.91, green: 0.91, blue: 0.87)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        BrushedMetalTexture()
                            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(Color.white.opacity(0.72), lineWidth: 2)
                    }
                    .shadow(color: Color.black.opacity(0.34), radius: 24, x: 0, y: 12)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)

                Rectangle()
                    .fill(Color(red: 0.24, green: 0.28, blue: 0.29).opacity(0.28))
                    .frame(height: 3)
                    .offset(y: -size.height * 0.32)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.72), Color.black.opacity(0.22)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 14, height: size.height * 0.19)
                    .overlay {
                        Capsule().stroke(Color.white.opacity(0.66), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.24), radius: 5, x: 2, y: 3)
                    .position(x: size.width - 28, y: size.height * 0.37)

                fridgeDetails(in: size)
                    .offset(x: parallax.width * 0.18, y: parallax.height * 0.18)

                LinearGradient(
                    colors: [Color.white.opacity(0.22), .clear, Color.black.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    private func fridgeDetails(in size: CGSize) -> some View {
        ZStack {
            FridgePhotoMagnet()
                .rotationEffect(.degrees(-5))
                .position(x: size.width * 0.18, y: size.height * 0.16)

            FridgeNoteMagnet(
                title: "KEEP GOING",
                lines: ["tiny steps", "count too"],
                color: Color(red: 1.0, green: 0.86, blue: 0.40)
            )
            .rotationEffect(.degrees(4))
            .position(x: size.width * 0.73, y: size.height * 0.16)

            FridgeSticker(symbol: "sparkles", color: SoloraTheme.coral)
                .position(x: size.width * 0.89, y: size.height * 0.51)

            FridgeSticker(symbol: "bolt.fill", color: SoloraTheme.gold)
                .position(x: size.width * 0.10, y: size.height * 0.57)

            FridgeNoteMagnet(
                title: "NEXT",
                lines: ["make it", "memorable"],
                color: Color(red: 0.68, green: 0.86, blue: 0.78)
            )
            .scaleEffect(0.86)
            .rotationEffect(.degrees(-3))
            .position(x: size.width * 0.83, y: size.height * 0.73)

            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill([SoloraTheme.coral, SoloraTheme.gold, SoloraTheme.plum][index % 3])
                    .frame(width: 10, height: 10)
                    .overlay { Circle().stroke(Color.white.opacity(0.62), lineWidth: 1) }
                    .shadow(color: Color.black.opacity(0.20), radius: 2, y: 1)
                    .position(
                        x: size.width * (0.13 + CGFloat(index) * 0.17),
                        y: size.height * 0.85 + CGFloat(index.isMultiple(of: 2) ? -4 : 4)
                    )
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct BrushedMetalTexture: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<46 {
                let y = CGFloat(index) / 45 * size.height
                let opacity = index.isMultiple(of: 3) ? 0.055 : 0.026
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.white.opacity(opacity)), lineWidth: 0.6)
            }
        }
    }
}

private struct FridgeNoteMagnet: View {
    let title: String
    let lines: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.5)
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .opacity(0.60)
            }
        }
        .foregroundStyle(SoloraTheme.ink)
        .padding(10)
        .frame(width: 86, height: 70, alignment: .topLeading)
        .background(color)
        .overlay(alignment: .top) {
            Circle()
                .fill(SoloraTheme.coral)
                .frame(width: 12, height: 12)
                .overlay { Circle().stroke(Color.white.opacity(0.68), lineWidth: 1) }
                .shadow(color: Color.black.opacity(0.22), radius: 2, y: 1)
                .offset(y: -6)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 4, x: 1, y: 3)
    }
}

private struct FridgePhotoMagnet: View {
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.33, green: 0.72, blue: 0.82), SoloraTheme.cream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Circle()
                    .fill(SoloraTheme.gold.opacity(0.88))
                    .frame(width: 20)
                    .offset(x: 20, y: -12)
                Capsule()
                    .fill(SoloraTheme.moss)
                    .frame(width: 74, height: 26)
                    .offset(x: -18, y: 25)
                Capsule()
                    .fill(SoloraTheme.plum.opacity(0.72))
                    .frame(width: 74, height: 22)
                    .offset(x: 28, y: 28)
            }
            .frame(width: 76, height: 58)
            .clipped()

            Text("A GOOD DAY")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(SoloraTheme.ink.opacity(0.64))
        }
        .padding(6)
        .background(SoloraTheme.paper)
        .shadow(color: Color.black.opacity(0.20), radius: 4, x: 1, y: 3)
    }
}

private struct FridgeSticker: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(Color.white)
            .frame(width: 34, height: 34)
            .background(color, in: Circle())
            .overlay { Circle().stroke(Color.white.opacity(0.84), lineWidth: 3) }
            .shadow(color: Color.black.opacity(0.20), radius: 3, y: 2)
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
            Canvas { context, _ in
                for (index, point) in points.enumerated() {
                    let diameter = CGFloat(112 + (index % 3) * 18)
                    context.stroke(
                        Path(ellipseIn: CGRect(
                            x: point.x - diameter / 2,
                            y: point.y - diameter / 2,
                            width: diameter,
                            height: diameter
                        )),
                        with: .color(Color.white.opacity(0.055)),
                        lineWidth: 1
                    )
                }
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

                for point in points {
                    context.fill(
                        Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)),
                        with: .color(Color.white.opacity(0.22))
                    )
                }
            }

        case .fridge:
            Canvas { context, _ in
                for point in points {
                    context.stroke(
                        Path(ellipseIn: CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)),
                        with: .color(SoloraTheme.ink.opacity(0.045)),
                        lineWidth: 1
                    )
                }
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
