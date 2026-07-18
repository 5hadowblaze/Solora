import Foundation
import SwiftUI

struct DeckPreviewSheet: View {
    let moments: [SoloraMoment]
    let target: String
    let onDismiss: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSlide: DeckPreviewSlide = .cover

    init(
        moments: [SoloraMoment],
        target: String = "",
        onDismiss: (() -> Void)? = nil
    ) {
        self.moments = moments
        self.target = target
        self.onDismiss = onDismiss
    }

    private var content: DeckPreviewContent {
        DeckPreviewContent(moments: moments, target: target)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeckPreviewBackdrop()

                if content.moments.isEmpty {
                    emptyState
                } else {
                    deck
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(SoloraTheme.paper)
    }

    private var deck: some View {
        VStack(spacing: 0) {
            header

            GeometryReader { proxy in
                let width = min(proxy.size.width - 36, 420)
                let height = min(proxy.size.height - 20, width / 0.74)

                TabView(selection: $selectedSlide) {
                    ForEach(DeckPreviewSlide.allCases) { slide in
                        DeckPreviewSlideView(
                            slide: slide,
                            content: content
                        )
                        .frame(width: width, height: height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 10)
                        .tag(slide)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Slide \(slide.position) of \(DeckPreviewSlide.allCases.count): \(slide.accessibilityTitle)")
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .accessibilityValue("Slide \(selectedSlide.position) of \(DeckPreviewSlide.allCases.count)")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: move(by: 1)
                    case .decrement: move(by: -1)
                    @unknown default: break
                    }
                }
            }

            controls
        }
        .sensoryFeedback(.selection, trigger: selectedSlide)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("SOLORA DECK")
                    .font(.caption2.weight(.black))
                    .tracking(1.8)
                    .foregroundStyle(SoloraTheme.coral)
                Text("Made from \(content.moments.count) real \(content.moments.count == 1 ? "memory" : "memories")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.52))
            }

            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.black))
                    .foregroundStyle(SoloraTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.58), in: Circle())
                    .soloraHairline(SoloraTheme.ink.opacity(0.08), radius: 22)
            }
            .buttonStyle(SoloraPressButtonStyle())
            .accessibilityLabel("Close deck preview")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 5) {
                ForEach(DeckPreviewSlide.allCases) { slide in
                    Capsule()
                        .fill(slide == selectedSlide ? SoloraTheme.coral : SoloraTheme.ink.opacity(0.13))
                        .frame(width: slide == selectedSlide ? 24 : 6, height: 6)
                }
            }
            .animation(reduceMotion ? nil : SoloraMotion.responsive, value: selectedSlide)
            .accessibilityHidden(true)

            HStack(spacing: 12) {
                Button {
                    move(by: -1)
                } label: {
                    Label("Back", systemImage: "arrow.left")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SoloraTheme.ink)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .soloraHairline(radius: 13)
                }
                .buttonStyle(SoloraPressButtonStyle())
                .disabled(selectedSlide == .cover)
                .opacity(selectedSlide == .cover ? 0.38 : 1)
                .accessibilityHint("Shows the previous slide")

                Text("\(selectedSlide.position) / \(DeckPreviewSlide.allCases.count)")
                    .font(.caption.monospacedDigit().weight(.black))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.52))
                    .frame(minWidth: 48)
                    .contentTransition(.numericText())
                    .accessibilityHidden(true)

                Button {
                    if selectedSlide == .nextSteps {
                        close()
                    } else {
                        move(by: 1)
                    }
                } label: {
                    HStack {
                        Text(selectedSlide == .nextSteps ? "Done" : "Next")
                        Spacer(minLength: 8)
                        Image(systemName: selectedSlide == .nextSteps ? "checkmark" : "arrow.right")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SoloraTheme.cream)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(SoloraPressButtonStyle())
                .accessibilityHint(selectedSlide == .nextSteps ? "Closes the deck preview" : "Shows the next slide")
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(SoloraTheme.gold.opacity(0.12))
                    .frame(width: 168, height: 168)
                    .blur(radius: 12)

                SoloraOrbView(
                    size: 108,
                    color: SoloraTheme.lavender,
                    showsHalo: true
                )
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Choose memories first")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(SoloraTheme.ink)
                Text("A Solora deck needs at least one real moment so every slide has proof behind it.")
                    .font(.subheadline)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Spacer()

            Button(action: close) {
                Text("Back to memory selection")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SoloraTheme.cream)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(SoloraPressButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
        .accessibilityElement(children: .contain)
    }

    private func move(by distance: Int) {
        let destination = min(
            max(selectedSlide.rawValue + distance, 0),
            DeckPreviewSlide.allCases.count - 1
        )
        guard let slide = DeckPreviewSlide(rawValue: destination) else { return }

        withAnimation(reduceMotion ? nil : SoloraMotion.spatial) {
            selectedSlide = slide
        }
    }

    private func close() {
        onDismiss?()
        dismiss()
    }
}

private enum DeckPreviewSlide: Int, CaseIterable, Identifiable {
    case cover
    case proof
    case insight
    case nextSteps

    var id: Self { self }
    var position: Int { rawValue + 1 }

    var accessibilityTitle: String {
        switch self {
        case .cover: "Cover"
        case .proof: "Selected-memory proof"
        case .insight: "Narrative insight"
        case .nextSteps: "Next steps"
        }
    }
}

private struct DeckPreviewContent {
    struct Memory: Identifiable {
        let id: String
        let title: String
        let summary: String
        let date: String
        let category: String
    }

    let moments: [Memory]
    let target: String
    let keywords: [String]
    let coverTitle: String
    let narrative: String
    let takeaway: String
    let nextSteps: [DeckNextStep]

    init(moments source: [SoloraMoment], target: String) {
        let selected = Array(source.prefix(3))
        self.target = target.trimmingCharacters(in: .whitespacesAndNewlines)
        moments = selected.enumerated().map { index, moment in
            Memory(
                id: moment.id,
                title: moment.title,
                summary: moment.summary,
                date: moment.date.formatted(.dateTime.month(.abbreviated).year()),
                category: Self.category(for: moment, index: index)
            )
        }

        keywords = Self.keywords(in: selected)
        coverTitle = Self.coverTitle(keywords: keywords, moments: selected)
        narrative = Self.narrative(for: selected)
        takeaway = Self.takeaway(keywords: keywords, moments: selected)
        nextSteps = Self.nextSteps(for: selected, keywords: keywords)
    }

    private static func category(for moment: SoloraMoment, index: Int) -> String {
        let category = moment.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return category.isEmpty ? "Proof \(String(format: "%02d", index + 1))" : category
    }

    private static func coverTitle(keywords: [String], moments: [SoloraMoment]) -> String {
        if let keyword = keywords.first {
            return "From \(keyword.lowercased())\nto momentum."
        }
        if let first = moments.first {
            return "From \(shortened(first.title, limit: 24).lowercased())\nto momentum."
        }
        return "From moments\nto momentum."
    }

    private static func narrative(for moments: [SoloraMoment]) -> String {
        switch moments.count {
        case 0:
            return ""
        case 1:
            return "“\(moments[0].title)” shows how one lived moment can become clear, reusable proof."
        case 2:
            return "Together, “\(moments[0].title)” and “\(moments[1].title)” reveal a pattern of turning experience into deliberate progress."
        default:
            return "From “\(moments[0].title)” through “\(moments[1].title)” to “\(moments[2].title),” the pattern is consistent: notice what matters, act with intent, and carry the learning forward."
        }
    }

    private static func takeaway(keywords: [String], moments: [SoloraMoment]) -> String {
        if keywords.count >= 2 {
            return "Your strongest through-line is \(keywords[0].lowercased()) backed by \(keywords[1].lowercased())."
        }
        if let first = moments.first {
            return "The through-line begins with real evidence: \(shortened(first.summary, limit: 92))"
        }
        return ""
    }

    private static func nextSteps(for moments: [SoloraMoment], keywords: [String]) -> [DeckNextStep] {
        guard let first = moments.first else { return [] }

        var steps = [
            DeckNextStep(
                title: "Lead with “\(shortened(first.title, limit: 34))”",
                detail: "Use this as the opening proof point: \(shortened(first.summary, limit: 88))",
                symbol: "quote.opening"
            )
        ]

        if moments.count > 1 {
            steps.append(
                DeckNextStep(
                    title: "Connect the pattern",
                    detail: "Bridge “\(shortened(first.title, limit: 24))” with “\(shortened(moments[1].title, limit: 24))” so the progression is explicit.",
                    symbol: "link"
                )
            )
        }

        let theme = keywords.first?.lowercased() ?? "progress"
        let finalMoment = moments.last ?? first
        steps.append(
            DeckNextStep(
                title: "Name the next chapter",
                detail: "Carry \(theme) forward from “\(shortened(finalMoment.title, limit: 30))” into one measurable next move.",
                symbol: "arrow.up.right"
            )
        )

        return Array(steps.prefix(3))
    }

    private static func keywords(in moments: [SoloraMoment]) -> [String] {
        let source = moments
            .flatMap { [$0.title, $0.summary, $0.category ?? ""] }
            .joined(separator: " ")
            .lowercased()
        let tokens = source
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 4 && !stopWords.contains($0) }

        var counts: [String: Int] = [:]
        var firstPosition: [String: Int] = [:]
        for (index, token) in tokens.enumerated() {
            counts[token, default: 0] += 1
            firstPosition[token, default: index] = min(firstPosition[token, default: index], index)
        }

        return counts.keys
            .sorted {
                let leftCount = counts[$0, default: 0]
                let rightCount = counts[$1, default: 0]
                if leftCount != rightCount { return leftCount > rightCount }
                return firstPosition[$0, default: 0] < firstPosition[$1, default: 0]
            }
            .prefix(3)
            .map { $0.capitalized }
    }

    private static func shortened(_ text: String, limit: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private static let stopWords: Set<String> = [
        "about", "after", "again", "behind", "could", "every", "first", "found", "from", "helped",
        "into", "learned", "moment", "people", "really", "their", "there", "these", "those", "through",
        "together", "turned", "using", "where", "which", "while", "would"
    ]
}

private struct DeckNextStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
}

private struct DeckPreviewBackdrop: View {
    var body: some View {
        ZStack {
            SoloraTheme.paper.ignoresSafeArea()

            Circle()
                .fill(SoloraTheme.coral.opacity(0.09))
                .frame(width: 310, height: 310)
                .blur(radius: 50)
                .offset(x: 180, y: -330)

            Circle()
                .fill(SoloraTheme.lavender.opacity(0.1))
                .frame(width: 270, height: 270)
                .blur(radius: 54)
                .offset(x: -190, y: 350)
        }
        .accessibilityHidden(true)
    }
}

private struct DeckPreviewSlideView: View {
    let slide: DeckPreviewSlide
    let content: DeckPreviewContent

    var body: some View {
        Group {
            switch slide {
            case .cover:
                DeckCoverSlide(content: content)
            case .proof:
                DeckProofSlide(content: content)
            case .insight:
                DeckInsightSlide(content: content)
            case .nextSteps:
                DeckNextStepsSlide(content: content)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.42), lineWidth: 1)
        }
        .shadow(color: SoloraTheme.plum.opacity(0.16), radius: 24, y: 14)
    }
}

private struct DeckCoverSlide: View {
    let content: DeckPreviewContent

    var body: some View {
        ZStack(alignment: .topLeading) {
            SoloraTheme.coral

            Circle()
                .fill(SoloraTheme.cream.opacity(0.94))
                .frame(width: 260, height: 260)
                .offset(x: 210, y: -105)

            Circle()
                .stroke(SoloraTheme.gold.opacity(0.78), lineWidth: 34)
                .frame(width: 250, height: 250)
                .offset(x: -150, y: 360)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("01 / 04")
                    Spacer()
                    Text("SOLORA")
                }
                .font(.caption2.weight(.black))
                .tracking(1.5)
                .opacity(0.56)

                Spacer()

                SoloraOrbView(
                    size: 74,
                    color: SoloraTheme.gold,
                    showsHalo: true
                )
                .accessibilityHidden(true)

                Spacer().frame(height: 24)

                Text(content.coverTitle)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .tracking(-1.2)
                    .minimumScaleFactor(0.72)
                    .lineLimit(3)

                Text(coverDescription)
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.68)
                    .padding(.top, 12)

                if let first = content.moments.first {
                    Text(first.title.uppercased())
                        .font(.caption2.weight(.black))
                        .tracking(1.2)
                        .lineLimit(2)
                        .padding(.top, 22)
                }
            }
            .foregroundStyle(SoloraTheme.ink)
            .padding(28)
        }
    }

    private var coverDescription: String {
        let memoryDescription = "\(content.moments.count) selected \(content.moments.count == 1 ? "memory" : "memories")"
        guard !content.target.isEmpty else {
            return "A four-page story built from \(memoryDescription)."
        }
        return "A four-page story for \(content.target), built from \(memoryDescription)."
    }
}

private struct DeckProofSlide: View {
    let content: DeckPreviewContent

    var body: some View {
        ZStack {
            SoloraTheme.cream

            VStack(alignment: .leading, spacing: 18) {
                DeckSlideHeader(
                    number: "02 / 04",
                    eyebrow: "SELECTED PROOF",
                    title: "The moments behind the story."
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(content.moments.enumerated()), id: \.element.id) { index, memory in
                            HStack(alignment: .top, spacing: 12) {
                                SoloraOrbView(
                                    size: 38,
                                    color: SoloraTheme.orbColors[index % SoloraTheme.orbColors.count]
                                )
                                .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(memory.category.uppercased())
                                        Spacer()
                                        Text(memory.date.uppercased())
                                    }
                                    .font(.caption2.weight(.black))
                                    .tracking(0.7)
                                    .foregroundStyle(SoloraTheme.coral)

                                    Text(memory.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(SoloraTheme.ink)
                                    Text(memory.summary)
                                        .font(.caption)
                                        .foregroundStyle(SoloraTheme.ink.opacity(0.6))
                                        .lineLimit(3)
                                }
                            }
                            .padding(13)
                            .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .soloraHairline(SoloraTheme.ink.opacity(0.07), radius: 14)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

private struct DeckInsightSlide: View {
    let content: DeckPreviewContent

    var body: some View {
        ZStack {
            SoloraTheme.ink

            Circle()
                .fill(SoloraTheme.lavender.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 28)
                .offset(x: 160, y: -200)

            VStack(alignment: .leading, spacing: 20) {
                DeckSlideHeader(
                    number: "03 / 04",
                    eyebrow: "THE INSIGHT",
                    title: "One pattern, repeated with intent.",
                    light: true
                )

                FlowLayout(spacing: 7) {
                    ForEach(content.keywords, id: \.self) { keyword in
                        Text(keyword.uppercased())
                            .font(.caption2.weight(.black))
                            .tracking(0.9)
                            .foregroundStyle(SoloraTheme.ink)
                            .padding(.horizontal, 10)
                            .frame(minHeight: 30)
                            .background(SoloraTheme.gold, in: Capsule())
                    }
                }

                Text(content.narrative)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(SoloraTheme.cream)
                    .minimumScaleFactor(0.82)

                Spacer()

                VStack(alignment: .leading, spacing: 7) {
                    Text("TAKEAWAY")
                        .font(.caption2.weight(.black))
                        .tracking(1.4)
                        .foregroundStyle(SoloraTheme.gold)
                    Text(content.takeaway)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SoloraTheme.cream.opacity(0.74))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
            }
            .padding(24)
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = layout(subviews: subviews, width: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? result.size.width, height: result.size.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(subviews: subviews, width: bounds.width)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(subviews: Subviews, width: CGFloat) -> (frames: [CGRect], size: CGSize) {
        var frames: [CGRect] = []
        var cursor = CGPoint.zero
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let itemSize = subview.sizeThatFits(.unspecified)
            let proposedX = cursor.x == 0 ? 0 : cursor.x + spacing

            if proposedX > 0, proposedX + itemSize.width > width {
                cursor.x = 0
                cursor.y += rowHeight + spacing
                rowHeight = 0
            } else {
                cursor.x = proposedX
            }

            let frame = CGRect(origin: cursor, size: itemSize)
            frames.append(frame)
            cursor.x += itemSize.width
            rowHeight = max(rowHeight, itemSize.height)
            usedWidth = max(usedWidth, frame.maxX)
        }

        let usedHeight = frames.isEmpty ? 0 : cursor.y + rowHeight
        return (frames, CGSize(width: usedWidth, height: usedHeight))
    }
}

private struct DeckNextStepsSlide: View {
    let content: DeckPreviewContent

    var body: some View {
        ZStack {
            SoloraTheme.paper

            Circle()
                .fill(SoloraTheme.gold.opacity(0.24))
                .frame(width: 210, height: 210)
                .blur(radius: 30)
                .offset(x: 170, y: 260)

            VStack(alignment: .leading, spacing: 18) {
                DeckSlideHeader(
                    number: "04 / 04",
                    eyebrow: "NEXT STEPS",
                    title: "Turn the story into movement."
                )

                VStack(spacing: 12) {
                    ForEach(Array(content.nextSteps.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: step.symbol)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(index == 0 ? SoloraTheme.cream : SoloraTheme.ink)
                                .frame(width: 38, height: 38)
                                .background(index == 0 ? SoloraTheme.coral : SoloraTheme.gold.opacity(0.62), in: Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(.subheadline.weight(.bold))
                                Text(step.detail)
                                    .font(.caption)
                                    .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                                    .lineLimit(3)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .soloraHairline(SoloraTheme.ink.opacity(0.07), radius: 15)
                        .accessibilityElement(children: .combine)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(SoloraTheme.coral)
                    Text("Every recommendation traces back to a selected memory.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.62))
                }
            }
            .foregroundStyle(SoloraTheme.ink)
            .padding(24)
        }
    }
}

private struct DeckSlideHeader: View {
    let number: String
    let eyebrow: String
    let title: String
    var light = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(eyebrow)
                    .foregroundStyle(light ? SoloraTheme.gold : SoloraTheme.coral)
                Spacer()
                Text(number)
                    .foregroundStyle(light ? SoloraTheme.cream.opacity(0.48) : SoloraTheme.ink.opacity(0.42))
            }
            .font(.caption2.weight(.black))
            .tracking(1.2)

            Text(title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(light ? SoloraTheme.cream : SoloraTheme.ink)
        }
    }
}
