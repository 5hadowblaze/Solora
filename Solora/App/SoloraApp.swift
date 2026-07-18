import SwiftUI
import FirebaseCore

@main
struct SoloraApp: App {
    init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            LaunchExperience()
        }
    }
}

private struct LaunchExperience: View {
    @State private var hasEntered = ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
    @State private var selectedVibe = "Warm & reflective"
    @State private var selectedVisualReference = "Inside Out orbs"

    var body: some View {
        Group {
            if hasEntered {
                RootTabView(
                    container: .demo,
                    vibe: selectedVibe,
                    visualReference: selectedVisualReference
                )
            } else {
                SoloraOnboarding { vibe, visualReference in
                    selectedVibe = vibe
                    selectedVisualReference = visualReference
                    withAnimation(.easeOut(duration: 0.28)) {
                        hasEntered = true
                    }
                }
            }
        }
    }
}

private struct SoloraOnboarding: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealSolora = false
    @State private var showSetup = false
    @State private var selectedVibe = "Warm & reflective"
    @State private var selectedVisualReference = "Inside Out orbs"
    @State private var brandSequenceTask: Task<Void, Never>?

    let enter: (String, String) -> Void

    private let ink = Color(red: 0.13, green: 0.08, blue: 0.07)
    private let cream = Color(red: 0.99, green: 0.94, blue: 0.84)
    private let coral = Color(red: 0.86, green: 0.27, blue: 0.20)
    private let gold = Color(red: 0.82, green: 0.57, blue: 0.18)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 20)

                    brandMoment
                        .padding(.top, 34)

                    if showSetup {
                        setup
                            .padding(.top, 30)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.bottom, 96)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button {
                    enter(selectedVibe, selectedVisualReference)
                } label: {
                    HStack(spacing: 10) {
                        Text("Enter my world")
                        Image(systemName: "arrow.right")
                            .font(.headline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(SoloraPrimaryButtonStyle(ink: ink, gold: gold))
                .accessibilityHint("Opens the Solora demo")
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(cream)
            }
        }
        .foregroundStyle(ink)
        .onAppear(perform: runBrandSequence)
        .onDisappear { brandSequenceTask?.cancel() }
    }

    private var header: some View {
        HStack {
            Text("SOLORA")
                .font(.caption.weight(.black))
                .tracking(2.4)
            Spacer()
            Text("A small beginning")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ink.opacity(0.62))
        }
        .padding(.horizontal, 24)
    }

    private var brandMoment: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(coral)
                    .frame(width: revealSolora ? 150 : 128, height: revealSolora ? 150 : 128)
                    .overlay(Circle().stroke(gold, lineWidth: 3).padding(8))
                    .shadow(color: coral.opacity(0.22), radius: 22, y: 12)

                Image(systemName: revealSolora ? "sparkle" : "wand.and.stars")
                    .font(.system(size: revealSolora ? 38 : 31, weight: .medium))
                    .foregroundStyle(cream)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(revealSolora ? "Solora" : "GPT-5.6 Sol + Lore + Aura")
                    .font(.system(size: revealSolora ? 48 : 28, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .contentTransition(.interpolate)
                    .minimumScaleFactor(0.75)

                if revealSolora {
                    Text("Your life becomes your lore.")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(ink.opacity(0.72))
                        .transition(.opacity)
                } else {
                    Text("A little intelligence. A lot more you.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ink.opacity(0.65))
                }
            }
            .padding(.horizontal, 24)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: revealSolora)
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Make my world feel like…")
                .font(.headline.weight(.bold))

            VStack(spacing: 8) {
                ForEach(["Warm & reflective", "Bold & ambitious", "Playful & curious"], id: \.self) { vibe in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                            selectedVibe = vibe
                        }
                    } label: {
                        HStack {
                            Text(vibe)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: selectedVibe == vibe ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedVibe == vibe ? coral : ink.opacity(0.42))
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(selectedVibe == vibe ? coral.opacity(0.10) : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ink.opacity(selectedVibe == vibe ? 0.30 : 0.14), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedVibe == vibe ? .isSelected : [])
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                Text("Visual reference")
                    .font(.subheadline.weight(.bold))

                FlowLayout(spacing: 8) {
                    ForEach(["Inside Out orbs", "Career Fridge magnets", "Quest Map"], id: \.self) { reference in
                        choiceChip(reference, isSelected: selectedVisualReference == reference) {
                            selectedVisualReference = reference
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                sourceStatus(title: "CV")
                sourceStatus(title: "Calendar")
            }
        }
        .padding(.horizontal, 24)
    }

    private func choiceChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18), action)
        } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.black))
                }
                Text(title)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isSelected ? cream : ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(isSelected ? ink : ink.opacity(0.06))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func sourceStatus(title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.bold))
            Label("Demo connected", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(gold)
            Text("Read-only source")
                .font(.caption2.weight(.medium))
                .foregroundStyle(ink.opacity(0.64))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(ink.opacity(0.045))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ink.opacity(0.14), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private func runBrandSequence() {
        brandSequenceTask?.cancel()
        guard !reduceMotion else {
            revealSolora = true
            showSetup = true
            return
        }

        brandSequenceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.28)) { revealSolora = true }

            try? await Task.sleep(nanoseconds: 570_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.28)) { showSetup = true }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .greatestFiniteMagnitude
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > width {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += (rowWidth == 0 ? 0 : spacing) + size.width
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? rowWidth, height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var point = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if point.x > bounds.minX, point.x + spacing + size.width > bounds.maxX {
                point.x = bounds.minX
                point.y += rowHeight + spacing
                rowHeight = 0
            }
            if point.x > bounds.minX { point.x += spacing }
            subview.place(at: point, proposal: ProposedViewSize(size))
            point.x += size.width
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct SoloraPrimaryButtonStyle: ButtonStyle {
    let ink: Color
    let gold: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.white)
            .background(ink.opacity(configuration.isPressed ? 0.86 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(gold.opacity(0.8), lineWidth: 1))
            .shadow(color: ink.opacity(0.18), radius: configuration.isPressed ? 4 : 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
