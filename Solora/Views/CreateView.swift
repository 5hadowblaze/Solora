import Foundation
import SwiftUI

struct CreateView: View {
    let moments: [SoloraMoment]
    let assistantStore: SoloraAssistantStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var mixerNamespace

    @State private var selectedIDs: Set<String>
    @State private var output: ShareOutput = .story
    @State private var phase: SharePhase = .select
    @State private var target = "Associate Product Manager"
    @State private var generationTask: Task<Void, Never>?
    @State private var showsMemorySelection = false
    @State private var showsTalkingPoints = false
    @State private var showsDeckPreview = false

    @Environment(\.openURL) private var openURL

    init(
        moments: [SoloraMoment] = DemoFixtures.moments,
        assistantStore: SoloraAssistantStore
    ) {
        self.moments = moments
        self.assistantStore = assistantStore
        _selectedIDs = State(initialValue: Set(moments.prefix(3).map(\.id)))
    }

    private var selectedMoments: [SoloraMoment] {
        moments.filter { selectedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (phase == .weaving ? SoloraTheme.ink : SoloraTheme.paper)
                    .ignoresSafeArea()
                    .animation(reduceMotion ? nil : SoloraMotion.responsive, value: phase)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        topBar

                        Group {
                            switch phase {
                            case .select:
                                selectionFlow
                            case .weaving:
                                GenerationTheatre(
                                    moments: selectedMoments,
                                    output: output,
                                    namespace: mixerNamespace
                                )
                                .frame(minHeight: 530)
                            case .result:
                                resultFlow
                            }
                        }
                        .id(phase)
                        .transition(reduceMotion ? .opacity : .soloraReveal)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sensoryFeedback(.selection, trigger: selectedIDs)
            .sensoryFeedback(.success, trigger: phase) { _, value in value == .result }
        }
        .onDisappear { generationTask?.cancel() }
        .sheet(isPresented: $showsMemorySelection) {
            MemorySelectionSheet(moments: moments, selectedIDs: $selectedIDs)
        }
        .sheet(isPresented: $showsTalkingPoints) {
            TalkingPointsSheet(moments: selectedMoments, target: target)
        }
        .sheet(isPresented: $showsDeckPreview) {
            DeckPreviewSheet(moments: selectedMoments, target: target)
        }
        .onChange(of: showsMemorySelection) { _, isPresented in
            if isPresented {
                assistantStore.beginChildPresentation(.memorySelection)
            } else {
                assistantStore.endChildPresentation(.memorySelection)
            }
        }
        .onChange(of: showsTalkingPoints) { _, isPresented in
            if isPresented {
                assistantStore.beginChildPresentation(.talkingPoints)
            } else {
                assistantStore.endChildPresentation(.talkingPoints)
            }
        }
        .onChange(of: showsDeckPreview) { _, isPresented in
            if isPresented {
                assistantStore.beginChildPresentation(.deckPreview)
            } else {
                assistantStore.endChildPresentation(.deckPreview)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text(phase == .weaving ? "Making…" : "Share")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(phase == .weaving ? SoloraTheme.cream : SoloraTheme.ink)
                .contentTransition(.interpolate)

            Spacer()

            if phase == .result {
                Button(action: reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SoloraTheme.ink)
                        .frame(width: 44, height: 44)
                        .background(SoloraTheme.ink.opacity(0.07), in: Circle())
                }
                .buttonStyle(SoloraPressButtonStyle())
                .accessibilityLabel("Start again")
            }
        }
    }

    private var selectionFlow: some View {
        VStack(alignment: .leading, spacing: 24) {
            targetField

            selectionButton(title: "Select memories")

            MemoryMixer(
                moments: moments,
                selectedIDs: $selectedIDs,
                namespace: mixerNamespace,
                onToggle: toggle
            )

            VStack(alignment: .leading, spacing: 11) {
                Text("Make")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.54))
                OutputPicker(selection: $output)
            }

            Button(action: makeArtifact) {
                HStack {
                    Text("Make from \(selectedMoments.count)")
                    Spacer()
                    Image(systemName: "wand.and.rays")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(SoloraTheme.cream)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(SoloraPressButtonStyle())
            .disabled(selectedMoments.isEmpty)
            .opacity(selectedMoments.isEmpty ? 0.42 : 1)
            .accessibilityHint("Combines the selected memories into a \(output.title)")
        }
    }

    private var targetField: some View {
        HStack(spacing: 12) {
            Text("For")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SoloraTheme.coral)

            TextField("Target or occasion", text: $target)
                .font(.subheadline.weight(.semibold))
                .textInputAutocapitalization(.words)

            Image(systemName: "pencil")
                .font(.caption.weight(.bold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.38))
        }
        .foregroundStyle(SoloraTheme.ink)
        .padding(.horizontal, 15)
        .frame(height: 50)
        .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 12))
        .soloraHairline(radius: 12)
    }

    private var resultFlow: some View {
        VStack(alignment: .leading, spacing: 18) {
            OutputPicker(selection: $output)

            selectedMemorySummary

            ArtifactPreview(
                output: output,
                moments: selectedMoments,
                target: target
            )
            .id(output)
            .transition(reduceMotion ? .opacity : .soloraReveal)

            outputActions
        }
    }

    private var selectedMemorySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Using \(selectedMoments.count) \(selectedMoments.count == 1 ? "memory" : "memories")")
                        .font(.subheadline.weight(.bold))
                    Text(selectedMoments.map(\.title).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                        .lineLimit(2)
                }
                Spacer(minLength: 12)
                Button("Change selection") { showsMemorySelection = true }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SoloraTheme.coral)
                    .frame(minHeight: 44)
            }
        }
        .padding(14)
        .background(SoloraTheme.ink.opacity(0.055), in: RoundedRectangle(cornerRadius: 13))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var outputActions: some View {
        switch output {
        case .story:
            brandedAction(title: "Share to Instagram", mark: .instagram) {
                openApp(primary: "instagram://", fallback: "https://www.instagram.com/")
            }
        case .post:
            VStack(spacing: 10) {
                brandedAction(title: "Share to LinkedIn", mark: .linkedIn) {
                    openApp(primary: "linkedin://", fallback: "https://www.linkedin.com/feed/")
                }
                brandedAction(title: "Share to X", mark: .x) {
                    let encoded = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    openApp(primary: "twitter://post?message=\(encoded)", fallback: "https://x.com/intent/post?text=\(encoded)")
                }
            }
        case .cv:
            brandedAction(title: "View in Google Docs", mark: .googleDocs) {
                openApp(primary: "googledocs://", fallback: "https://docs.google.com/document/u/0/")
            }
            Text("Opens Google Docs so you can paste or continue editing this CV. This preview has not been uploaded.")
                .font(.caption)
                .foregroundStyle(SoloraTheme.ink.opacity(0.54))
        case .interview:
            primaryAction(title: "Open talking points", symbol: "quote.bubble.fill") {
                showsTalkingPoints = true
            }
        case .deck:
            primaryAction(title: "Open deck preview", symbol: "rectangle.on.rectangle.angled") {
                showsDeckPreview = true
            }
        }
    }

    private func selectionButton(title: String) -> some View {
        Button { showsMemorySelection = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "checklist.checked")
                    .font(.headline.weight(.bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline.weight(.bold))
                    Text("\(selectedMoments.count) selected from \(moments.count)")
                        .font(.caption.weight(.medium))
                        .opacity(0.62)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.black))
            }
            .foregroundStyle(SoloraTheme.ink)
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 14))
            .soloraHairline(radius: 14)
        }
        .buttonStyle(SoloraPressButtonStyle())
        .accessibilityHint("Choose one or more memories for this output")
    }

    private func primaryAction(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: symbol)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(SoloraTheme.cream)
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(SoloraPressButtonStyle())
    }

    private func brandedAction(title: String, mark: ShareBrandMark, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ShareBrandIcon(mark: mark)
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(SoloraTheme.cream)
            .padding(.horizontal, 14)
            .frame(height: 56)
            .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(SoloraPressButtonStyle())
        .accessibilityLabel(title)
    }

    private func openApp(primary: String, fallback: String) {
        guard let primaryURL = URL(string: primary), let fallbackURL = URL(string: fallback) else { return }
        openURL(primaryURL) { accepted in
            if !accepted { openURL(fallbackURL) }
        }
    }

    private var shareText: String {
        switch output {
        case .cv:
            return selectedMoments.map { "• \($0.title): \($0.summary)" }.joined(separator: "\n")
        case .interview:
            return "Talking points for \(target):\n" + selectedMoments.map(\.summary).joined(separator: "\n")
        case .post:
            return selectedMoments.map { "\($0.title): \($0.summary)" }.joined(separator: "\n\n")
        case .story:
            return selectedMoments.map { "\($0.title) — \($0.summary)" }.joined(separator: "\n")
        case .deck:
            return "From moments to momentum:\n" + selectedMoments.map { "• \($0.title): \($0.summary)" }.joined(separator: "\n")
        }
    }

    private func toggle(_ moment: SoloraMoment) {
        withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
            if selectedIDs.contains(moment.id) {
                selectedIDs.remove(moment.id)
                return
            }

            selectedIDs.insert(moment.id)
        }
    }

    private func makeArtifact() {
        generationTask?.cancel()
        withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.spatial) {
            phase = .weaving
        }

        generationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 520 : 1_750))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeOut(duration: 0.18) : SoloraMotion.spatial) {
                phase = .result
            }
        }
    }

    private func reset() {
        generationTask?.cancel()
        withAnimation(reduceMotion ? nil : SoloraMotion.spatial) {
            phase = .select
        }
    }
}

private enum SharePhase: Hashable {
    case select
    case weaving
    case result
}

private enum ShareOutput: String, CaseIterable, Identifiable {
    case story
    case post
    case cv
    case interview
    case deck

    var id: Self { self }

    var title: String {
        switch self {
        case .story: "Story"
        case .post: "Post"
        case .cv: "CV"
        case .interview: "Talk"
        case .deck: "Deck"
        }
    }

    var symbol: String {
        switch self {
        case .story: "rectangle.portrait.fill"
        case .post: "text.bubble.fill"
        case .cv: "doc.text.fill"
        case .interview: "quote.bubble.fill"
        case .deck: "rectangle.on.rectangle.angled"
        }
    }

    var actionTitle: String {
        switch self {
        case .cv: "Export CV"
        case .interview: "Open talking points"
        case .deck: "Open deck preview"
        case .post: "Share post"
        case .story: "Share Story"
        }
    }
}

enum ShareBrandMark {
    case instagram
    case linkedIn
    case x
    case googleDocs
}

struct ShareBrandIcon: View {
    let mark: ShareBrandMark

    var body: some View {
        Group {
            switch mark {
            case .instagram:
                RoundedRectangle(cornerRadius: 7)
                    .stroke(lineWidth: 2)
                    .overlay {
                        Circle().stroke(lineWidth: 2).frame(width: 9, height: 9)
                        Circle().fill(SoloraTheme.cream).frame(width: 3, height: 3).offset(x: 7, y: -7)
                    }
            case .linkedIn:
                RoundedRectangle(cornerRadius: 4)
                    .fill(SoloraTheme.cream)
                    .overlay {
                        Text("in")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(SoloraTheme.ink)
                            .offset(y: -1)
                    }
            case .x:
                Text("𝕏")
                    .font(.system(size: 20, weight: .bold))
            case .googleDocs:
                UnevenRoundedRectangle(
                    topLeadingRadius: 3,
                    bottomLeadingRadius: 3,
                    bottomTrailingRadius: 3,
                    topTrailingRadius: 8
                )
                .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                .overlay(alignment: .bottom) {
                    VStack(spacing: 3) {
                        Capsule().frame(width: 13, height: 2)
                        Capsule().frame(width: 13, height: 2)
                        Capsule().frame(width: 9, height: 2)
                    }
                    .foregroundStyle(.white)
                    .padding(.bottom, 5)
                }
            }
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }
}

private struct OutputPicker: View {
    @Binding var selection: ShareOutput
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNamespace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShareOutput.allCases) { output in
                    Button {
                        withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
                            selection = output
                        }
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: output.symbol)
                                .font(.system(size: 18, weight: .semibold))
                                .symbolEffect(.bounce, value: selection == output)
                            Text(output.title)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(selection == output ? SoloraTheme.cream : SoloraTheme.ink)
                        .frame(width: 67, height: 66)
                        .background {
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color.white.opacity(0.48))

                            if selection == output {
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(SoloraTheme.ink)
                                    .matchedGeometryEffect(
                                        id: "share-output-selection",
                                        in: selectionNamespace
                                    )
                            }
                        }
                        .soloraHairline(
                            selection == output ? SoloraTheme.ink : SoloraTheme.ink.opacity(0.08),
                            radius: 11
                        )
                    }
                    .buttonStyle(SoloraPressButtonStyle())
                    .accessibilityAddTraits(selection == output ? .isSelected : [])
                }
            }
        }
        .contentMargins(.horizontal, 0, for: .scrollContent)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct MemoryMixer: View {
    let moments: [SoloraMoment]
    @Binding var selectedIDs: Set<String>
    let namespace: Namespace.ID
    let onToggle: (SoloraMoment) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SoloraTheme.ink)

            Circle()
                .stroke(SoloraTheme.cream.opacity(0.10), lineWidth: 34)
                .frame(width: 230, height: 230)
                .offset(x: 120, y: -110)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Choose your proof")
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Text("\(selectedIDs.count) selected")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(SoloraTheme.gold)
                }

                HStack(alignment: .top, spacing: 8) {
                    ForEach(Array(moments.prefix(5).enumerated()), id: \.element.id) { index, moment in
                        let selected = selectedIDs.contains(moment.id)
                        Button { onToggle(moment) } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .bottomTrailing) {
                                    SoloraOrbView(
                                        size: selected ? 58 : 48,
                                        color: SoloraTheme.orbColors[index % SoloraTheme.orbColors.count],
                                        showsHalo: selected,
                                        mediaPath: moment.photoPaths.first ?? moment.stickerPath
                                    )
                                    .matchedGeometryEffect(id: "mixer-\(moment.id)", in: namespace)

                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(.caption2.weight(.black))
                                            .foregroundStyle(SoloraTheme.ink)
                                            .frame(width: 20, height: 20)
                                            .background(SoloraTheme.cream, in: Circle())
                                    }
                                }

                                Text(short(moment.title))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(SoloraTheme.cream.opacity(selected ? 1 : 0.55))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 56)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SoloraPressButtonStyle(pressedScale: 0.94))
                        .accessibilityLabel(moment.title)
                        .accessibilityValue(selected ? "Selected" : "Not selected")
                    }
                }

                Text(selectedSummary)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SoloraTheme.cream.opacity(0.58))
                    .lineLimit(1)
            }
            .padding(16)
        }
        .frame(height: 226)
        .soloraHairline(Color.white.opacity(0.08), radius: 18)
    }

    private var selectedSummary: String {
        let selected = moments.filter { selectedIDs.contains($0.id) }
        return selected.map { short($0.title) }.joined(separator: "  ·  ")
    }

    private func short(_ title: String) -> String {
        title
            .replacingOccurrences(of: "Found ", with: "")
            .replacingOccurrences(of: "Made ", with: "")
            .replacingOccurrences(of: "Built ", with: "")
            .replacingOccurrences(of: "Aligned ", with: "")
            .replacingOccurrences(of: "Shipped ", with: "")
    }
}

private struct GenerationTheatre: View {
    let moments: [SoloraMoment]
    let output: ShareOutput
    let namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var trigger = 0

    var body: some View {
        Group {
            if reduceMotion {
                theatre(phase: .unfold)
            } else {
                theatre(phase: .apart)
                    .phaseAnimator(WeavePhase.allCases, trigger: trigger) { _, phase in
                        theatre(phase: phase)
                    } animation: { phase in phase.animation }
            }
        }
        .onAppear { trigger += 1 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Making a \(output.title) from \(moments.count) memories")
    }

    private func theatre(phase: WeavePhase) -> some View {
        VStack(spacing: 26) {
            ZStack {
                Circle()
                    .stroke(SoloraTheme.gold.opacity(phase.ringOpacity), lineWidth: 2)
                    .frame(width: 230, height: 230)
                    .scaleEffect(phase.ringScale)

                RoundedRectangle(cornerRadius: phase == .unfold ? 16 : 80, style: .continuous)
                    .fill(SoloraTheme.cream)
                    .frame(width: phase.artifactSize.width, height: phase.artifactSize.height)
                    .opacity(phase.artifactOpacity)
                    .overlay {
                        Image(systemName: output.symbol)
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(SoloraTheme.coral)
                            .opacity(phase.artifactOpacity)
                    }

                ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                    SoloraOrbView(
                        size: 62,
                        color: SoloraTheme.orbColors[index % SoloraTheme.orbColors.count],
                        showsHalo: phase == .orbit,
                        mediaPath: moment.photoPaths.first ?? moment.stickerPath
                    )
                    .matchedGeometryEffect(id: "mixer-\(moment.id)", in: namespace)
                    .offset(orbOffset(index: index, phase: phase))
                    .scaleEffect(phase.orbScale)
                    .opacity(phase.orbOpacity)
                }
            }
            .frame(height: 330)

            VStack(spacing: 5) {
                Text(phase == .unfold ? output.title : "Gathering your threads")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .contentTransition(.interpolate)
                Text(phase == .unfold ? "Ready" : "\(moments.count) real moments")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SoloraTheme.cream.opacity(0.56))
            }
            .foregroundStyle(SoloraTheme.cream)
        }
    }

    private func orbOffset(index: Int, phase: WeavePhase) -> CGSize {
        let apart = [CGSize(width: -105, height: -56), .init(width: 100, height: -42), .init(width: 0, height: 104)]
        let orbit = [CGSize(width: -78, height: -78), .init(width: 94, height: 4), .init(width: -38, height: 96)]

        switch phase {
        case .apart: return apart[index % apart.count]
        case .orbit: return orbit[index % orbit.count]
        case .gather, .unfold: return .zero
        }
    }
}

private enum WeavePhase: CaseIterable {
    case apart, orbit, gather, unfold

    var orbScale: CGFloat {
        switch self {
        case .apart, .orbit: 1
        case .gather: 0.52
        case .unfold: 0.22
        }
    }

    var orbOpacity: Double {
        switch self {
        case .apart, .orbit, .gather: 1
        case .unfold: 0
        }
    }

    var ringOpacity: Double { self == .apart ? 0.10 : self == .unfold ? 0 : 0.62 }
    var ringScale: CGFloat { self == .gather ? 0.52 : self == .unfold ? 1.28 : 1 }
    var artifactOpacity: Double { self == .unfold ? 1 : self == .gather ? 0.22 : 0 }
    var artifactSize: CGSize { self == .unfold ? CGSize(width: 174, height: 230) : CGSize(width: 72, height: 72) }

    var animation: Animation {
        switch self {
        case .apart: .linear(duration: 0.01)
        case .orbit: .spring(duration: 0.38, bounce: 0.12)
        case .gather: .timingCurve(0.77, 0, 0.175, 1, duration: 0.40)
        case .unfold: .spring(duration: 0.46, bounce: 0.08)
        }
    }
}

private struct ArtifactPreview: View {
    let output: ShareOutput
    let moments: [SoloraMoment]
    let target: String

    var body: some View {
        Group {
            switch output {
            case .story: story
            case .post: post
            case .cv: cv
            case .interview: interview
            case .deck: deck
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Generated \(output.title) preview")
    }

    private var story: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SoloraTheme.coral)

            Circle()
                .stroke(SoloraTheme.gold, lineWidth: 54)
                .frame(width: 300, height: 300)
                .offset(x: 170, y: -200)

            VStack(alignment: .leading, spacing: 10) {
                Spacer()
                Text(String(format: "%02d", moments.count))
                    .font(.system(size: 82, weight: .black, design: .rounded))
                    .tracking(-4)
                Text(storyHeadline)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .lineLimit(4)
                Text("SOLORA · JULY")
                    .font(.caption2.weight(.black))
                    .tracking(1.6)
                    .opacity(0.56)
            }
            .padding(22)
        }
        .foregroundStyle(SoloraTheme.ink)
        .frame(width: 270, height: 430)
    }

    private var storyHeadline: String {
        guard let first = moments.first else { return "A clearer next step" }
        if moments.count == 1 { return first.title }
        return "\(first.title)\nand \(moments.count - 1) more turning \(moments.count == 2 ? "point" : "points")"
    }

    private var post: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Circle().fill(SoloraTheme.coral).frame(width: 40, height: 40)
                    .overlay { Text("A").font(.headline.bold()).foregroundStyle(.white) }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Amir").font(.subheadline.weight(.bold))
                    Text("now").font(.caption).opacity(0.48)
                }
            }
            Text(moments.first?.title ?? "A career moment worth sharing")
                .font(.title3.weight(.bold))
            Text(moments.first?.summary ?? "A new perspective became a useful next step.")
                .font(.body)
                .foregroundStyle(SoloraTheme.ink.opacity(0.66))
            Text("#product #learning")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SoloraTheme.coral)
        }
        .foregroundStyle(SoloraTheme.ink)
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .soloraHairline(radius: 16)
    }

    private var cv: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AMIR DZAKWAN").font(.headline.weight(.black)).tracking(0.8)
                    Text(target).font(.caption.weight(.semibold)).foregroundStyle(SoloraTheme.coral)
                }
                Spacer()
                Text("01").font(.title2.monospacedDigit().weight(.black)).opacity(0.16)
            }
            Divider()
            Text("SELECTED EXPERIENCE").font(.caption2.weight(.black)).tracking(1.4)
            ForEach(moments.prefix(3)) { moment in
                VStack(alignment: .leading, spacing: 3) {
                    Text(moment.title).font(.subheadline.weight(.bold))
                    Text(moment.summary).font(.caption).foregroundStyle(SoloraTheme.ink.opacity(0.62))
                }
            }
        }
        .foregroundStyle(SoloraTheme.ink)
        .padding(22)
        .frame(minHeight: 410, alignment: .top)
        .background(.white, in: RoundedRectangle(cornerRadius: 10))
        .soloraHairline(radius: 10)
    }

    private var interview: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TALKING POINTS")
                .font(.caption.weight(.black))
                .tracking(1.6)
                .foregroundStyle(SoloraTheme.gold)
                .padding(.bottom, 20)

            ForEach(Array(moments.prefix(3).enumerated()), id: \.element.id) { index, moment in
                HStack(alignment: .top, spacing: 14) {
                    Text("0\(index + 1)")
                        .font(.caption.monospacedDigit().weight(.black))
                        .foregroundStyle(SoloraTheme.coral)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(moment.title).font(.headline)
                        Text(moment.summary).font(.caption).opacity(0.62)
                    }
                }
                .padding(.vertical, 14)
                if index < min(moments.count, 3) - 1 { Divider().overlay(Color.white.opacity(0.12)) }
            }
        }
        .foregroundStyle(SoloraTheme.cream)
        .padding(20)
        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 16))
    }

    private var deck: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(SoloraTheme.ink).offset(x: 8, y: 10)
            RoundedRectangle(cornerRadius: 16).fill(SoloraTheme.gold).offset(x: 4, y: 5)
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16).fill(SoloraTheme.coral)
                Circle()
                    .fill(SoloraTheme.cream)
                    .frame(width: 180, height: 180)
                    .offset(x: 220, y: -85)
                VStack(alignment: .leading, spacing: 8) {
                    Text("01 / 05").font(.caption2.weight(.black)).tracking(1.4).opacity(0.54)
                    Spacer()
                    Text(moments.first?.title ?? "From moments\nto momentum.")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .lineLimit(3)
                }
                .padding(20)
            }
        }
        .foregroundStyle(SoloraTheme.ink)
        .frame(height: 235)
        .padding(.trailing, 8)
        .padding(.bottom, 10)
    }
}
