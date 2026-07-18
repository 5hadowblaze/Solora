import SwiftUI

struct SoloraOnboarding: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: SoloraOnboardingStep = .welcome
    @State private var includedSources: Set<SoloraOnboardingSource> = [.cv, .calendar]
    @State private var selectedVibe = "Warm & reflective"
    @State private var selectedVisualReference = "Core room"
    @State private var showsChatGPTImport = false
    @State private var importedMemoryCount = 0

    let userID: String
    let enter: (String, String) -> Void

    var body: some View {
        ZStack {
            background

            currentStep
                .id(step)
                .transition(reduceMotion ? .opacity : .soloraReveal)

            VStack {
                SoloraOnboardingProgressHeader(
                    step: step,
                    usesLightForeground: step == .learning,
                    canGoBack: step != .welcome,
                    onBack: goBack
                )
                .padding(.horizontal, 20)
                .padding(.top, 4)

                Spacer()
            }
        }
        .foregroundStyle(step == .learning ? SoloraTheme.cream : SoloraTheme.ink)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomAction
        }
        .sheet(isPresented: $showsChatGPTImport) {
            ChatGPTMemoryImportSheet(userID: userID) { count in
                withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
                    _ = includedSources.insert(.chatGPT)
                    importedMemoryCount += count
                }
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        if step == .learning {
            SoloraTheme.ink.ignoresSafeArea()
        } else {
            ZStack {
                SoloraTheme.cream
                RadialGradient(
                    colors: [SoloraTheme.gold.opacity(step == .ready ? 0.20 : 0.11), .clear],
                    center: .topTrailing,
                    startRadius: 8,
                    endRadius: 420
                )
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var currentStep: some View {
        switch step {
        case .welcome:
            welcome
        case .sources:
            sources
        case .personalization:
            personalization
        case .learning:
            SoloraOnboardingLearningView(
                sources: orderedSources,
                onFinished: showReady
            )
        case .ready:
            ready
        }
    }

    private var welcome: some View {
        ZStack {
            SoloraKineticOrbField(seeds: SoloraOnboardingOrbSeed.welcome)
                .padding(.top, 52)
                .padding(.bottom, 82)

            VStack(spacing: 0) {
                Spacer(minLength: 112)

                SoloraOnboardingGlassOrb(
                    size: 132,
                    color: SoloraTheme.coral,
                    isAlive: true,
                    showsHalo: true
                )
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(SoloraTheme.cream)
                }
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Solora")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .tracking(-1.6)
                    Text("Your life becomes your lore.")
                        .font(.title3.weight(.semibold))
                    Text("Gather the moments that shaped you, then watch them become a world you can use.")
                        .font(.body.weight(.medium))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 330)
                }
                .padding(.top, 28)

                Spacer(minLength: 116)
            }
            .padding(.horizontal, 24)
        }
    }

    private var sources: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                onboardingHeading(
                    eyebrow: "BRING YOUR STORY IN",
                    title: "Start with what already knows you",
                    detail: "Choose the parts of your working life you want Solora to shape around. You can change these choices later."
                )

                VStack(spacing: 12) {
                    ForEach(SoloraOnboardingSource.allCases) { source in
                        SoloraOnboardingSourceCard(
                            source: source,
                            isIncluded: includedSources.contains(source)
                        ) {
                            toggle(source)
                        }
                    }
                }

                Label(
                    "Solora only saves content you deliberately capture or approve.",
                    systemImage: "lock.fill"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.54))
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 86)
            .padding(.bottom, 112)
        }
    }

    private var personalization: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                onboardingHeading(
                    eyebrow: "MAKE IT YOURS",
                    title: "How should your world feel?",
                    detail: "Your choices shape its colour, movement and voice—not just a theme."
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose your energy")
                        .font(.headline.weight(.bold))

                    HStack(spacing: 8) {
                        vibeChoice("Warm", value: "Warm & reflective", color: SoloraTheme.gold)
                        vibeChoice("Bold", value: "Bold & ambitious", color: SoloraTheme.coral)
                        vibeChoice("Playful", value: "Playful & curious", color: SoloraTheme.lavender)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose a starting world")
                        .font(.headline.weight(.bold))

                    HStack(spacing: 9) {
                        worldChoice("Core room", symbol: "circle.grid.3x3.fill", color: SoloraTheme.coral)
                        worldChoice("Career fridge", symbol: "refrigerator.fill", color: SoloraTheme.gold)
                        worldChoice("Quest map", symbol: "point.3.connected.trianglepath.dotted", color: SoloraTheme.lavender)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 86)
            .padding(.bottom, 112)
        }
    }

    private var ready: some View {
        ZStack {
            SoloraKineticOrbField(seeds: SoloraOnboardingOrbSeed.welcome.map {
                .init(
                    id: $0.id,
                    x: $0.x,
                    y: min(0.72, $0.y),
                    size: $0.size * 0.78,
                    depth: $0.depth,
                    color: $0.color,
                    phase: $0.phase
                )
            })
            .opacity(0.78)
            .padding(.top, 70)
            .padding(.bottom, 120)

            VStack(spacing: 0) {
                Spacer(minLength: 108)

                ZStack {
                    Circle()
                        .fill(SoloraTheme.gold.opacity(0.16))
                        .frame(width: 250, height: 250)
                        .blur(radius: 36)
                    SoloraOnboardingGlassOrb(
                        size: 166,
                        color: SoloraTheme.gold,
                        isAlive: true,
                        showsHalo: true
                    )
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(SoloraTheme.cream)
                }
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Your world is ready")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(readyDetail)
                        .font(.body.weight(.medium))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 320)
                    Label(selectedVisualReference, systemImage: "circle.grid.3x3.fill")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(.white.opacity(0.52), in: Capsule())
                        .soloraHairline(SoloraTheme.ink.opacity(0.08), radius: 20)
                        .padding(.top, 4)
                }
                .padding(.top, 26)

                Spacer(minLength: 116)
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var bottomAction: some View {
        switch step {
        case .welcome:
            actionContainer {
                SoloraOnboardingPrimaryButton(title: "Begin") {
                    advance(to: .sources)
                }
            }
        case .sources:
            actionContainer {
                SoloraOnboardingPrimaryButton(
                    title: "Continue",
                    detail: sourceButtonDetail
                ) {
                    advance(to: .personalization)
                }
            }
        case .personalization:
            actionContainer {
                SoloraOnboardingPrimaryButton(
                    title: "Let Solora learn",
                    detail: "Using the choices and memories you reviewed"
                ) {
                    advance(to: .learning)
                }
            }
        case .learning:
            Button("Skip animation", action: showReady)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SoloraTheme.cream.opacity(0.72))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(SoloraTheme.ink.opacity(0.78))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        case .ready:
            actionContainer {
                SoloraOnboardingPrimaryButton(title: "Enter my world") {
                    enter(selectedVibe, selectedVisualReference)
                }
            }
        }
    }

    private func actionContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [SoloraTheme.cream.opacity(0), SoloraTheme.cream, SoloraTheme.cream],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private func onboardingHeading(eyebrow: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.caption.weight(.black))
                .tracking(1.4)
                .foregroundStyle(SoloraTheme.coral)
            Text(title)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(-0.7)
            Text(detail)
                .font(.body.weight(.medium))
                .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                .lineSpacing(3)
        }
    }

    private func vibeChoice(_ title: String, value: String, color: Color) -> some View {
        SoloraOnboardingChoicePill(
            title: title,
            color: color,
            isSelected: selectedVibe == value
        ) {
            withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
                selectedVibe = value
            }
        }
    }

    private func worldChoice(_ title: String, symbol: String, color: Color) -> some View {
        SoloraOnboardingWorldCard(
            title: title,
            symbol: symbol,
            color: color,
            isSelected: selectedVisualReference == title
        ) {
            withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
                selectedVisualReference = title
            }
        }
    }

    private var orderedSources: [SoloraOnboardingSource] {
        SoloraOnboardingSource.allCases.filter(includedSources.contains)
    }

    private var sourceButtonDetail: String {
        if includedSources.isEmpty {
            return "You can begin without adding a source"
        }
        return "\(includedSources.count) source \(includedSources.count == 1 ? "choice" : "choices") included"
    }

    private var readyDetail: String {
        if importedMemoryCount == 1 {
            return "Your reviewed ChatGPT memory is saved and ready to explore."
        }
        if importedMemoryCount > 1 {
            return "\(importedMemoryCount) reviewed ChatGPT memories are saved and ready to explore."
        }
        return "Your choices are set. Capture a useful moment to begin growing your lore."
    }

    private func toggle(_ source: SoloraOnboardingSource) {
        if source == .chatGPT {
            showsChatGPTImport = true
            return
        }

        withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
            if includedSources.contains(source) {
                includedSources.remove(source)
            } else {
                _ = includedSources.insert(source)
            }
        }
    }

    private func advance(to newStep: SoloraOnboardingStep) {
        withAnimation(reduceMotion ? .easeOut(duration: 0.18) : SoloraMotion.reveal) {
            step = newStep
        }
    }

    private func showReady() {
        guard step == .learning else { return }
        advance(to: .ready)
    }

    private func goBack() {
        let destination: SoloraOnboardingStep
        switch step {
        case .welcome: return
        case .sources: destination = .welcome
        case .personalization: destination = .sources
        case .learning, .ready: destination = .personalization
        }
        advance(to: destination)
    }
}
