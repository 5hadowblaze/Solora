import SwiftUI
import FirebaseCore

@main
struct SoloraApp: App {
    @StateObject private var authenticationSession: AuthenticationSession

    init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }

        let arguments = ProcessInfo.processInfo.arguments
        let bypassesAuthentication = arguments.contains("-skipOnboarding") || arguments.contains("-skipAuthentication")
        _authenticationSession = StateObject(
            wrappedValue: AuthenticationSession(bypassesAuthentication: bypassesAuthentication)
        )
    }

    var body: some Scene {
        WindowGroup {
            LaunchExperience(authenticationSession: authenticationSession)
                .onOpenURL { authenticationSession.handleOpenURL($0) }
        }
    }
}

private struct LaunchExperience: View {
    @ObservedObject var authenticationSession: AuthenticationSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasEntered = ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
    @State private var selectedVibe = "Warm & reflective"
    @State private var selectedVisualReference = "Core room"

    var body: some View {
        Group {
            if !hasEntered {
                SoloraOnboarding { vibe, visualReference in
                    selectedVibe = vibe
                    selectedVisualReference = visualReference
                    withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.reveal) {
                        hasEntered = true
                    }
                }
                .transition(.opacity)
            } else {
                authenticatedExperience
                    .transition(reduceMotion ? .opacity : .soloraReveal)
            }
        }
    }

    @ViewBuilder
    private var authenticatedExperience: some View {
        switch authenticationSession.state {
        case .checking:
            AuthenticationLoadingView()
        case .signedOut:
            AuthenticationView(session: authenticationSession)
        case .signedIn(let user):
            RootTabView(
                container: .demo,
                vibe: selectedVibe,
                visualReference: selectedVisualReference,
                authenticatedUser: user,
                signOut: authenticationSession.signOut
            )
        }
    }
}

private struct SoloraOnboarding: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var resolvedBrand = false
    @State private var showsSetup = false
    @State private var selectedVibe = "Warm & reflective"
    @State private var selectedVisualReference = "Core room"
    @State private var brandTask: Task<Void, Never>?

    let enter: (String, String) -> Void

    var body: some View {
        ZStack {
            SoloraTheme.cream.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    brandMoment
                        .padding(.top, showsSetup ? 20 : 82)

                    if showsSetup {
                        setup
                            .padding(.top, 24)
                            .transition(reduceMotion ? .opacity : .soloraReveal)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsSetup {
                    Button {
                        enter(selectedVibe, selectedVisualReference)
                    } label: {
                        HStack {
                            Text("Enter Solora")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SoloraTheme.cream)
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(SoloraPressButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(SoloraTheme.cream)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .foregroundStyle(SoloraTheme.ink)
        .onAppear(perform: runBrandSequence)
        .onDisappear { brandTask?.cancel() }
    }

    private var brandMoment: some View {
        VStack(spacing: 18) {
            ZStack {
                SoloraOrbView(
                    size: showsSetup ? 112 : 164,
                    color: SoloraTheme.coral,
                    isAlive: resolvedBrand,
                    showsHalo: resolvedBrand
                )
                .scaleEffect(resolvedBrand ? 1 : 0.88)

                Image(systemName: resolvedBrand ? "circle.fill" : "wand.and.rays")
                    .font(.system(size: resolvedBrand ? 25 : 34, weight: .bold))
                    .foregroundStyle(SoloraTheme.cream)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(resolvedBrand ? "Solora" : "GPT-5.6 Sol + Lore + Aura")
                    .font(.system(size: resolvedBrand ? 46 : 25, weight: .black, design: .rounded))
                    .tracking(resolvedBrand ? -1.6 : -0.5)
                    .multilineTextAlignment(.center)
                    .contentTransition(.interpolate)

                Text(resolvedBrand ? "Your life becomes your lore." : "Sol  ·  Lore  ·  Aura")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.56))
                    .contentTransition(.interpolate)
            }
        }
        .animation(reduceMotion ? nil : SoloraMotion.spatial, value: resolvedBrand)
        .animation(reduceMotion ? nil : SoloraMotion.spatial, value: showsSetup)
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 11) {
                Text("Choose your energy")
                    .font(.title3.weight(.bold))

                HStack(spacing: 8) {
                    vibeChoice("Warm", value: "Warm & reflective", color: SoloraTheme.gold)
                    vibeChoice("Bold", value: "Bold & ambitious", color: SoloraTheme.coral)
                    vibeChoice("Playful", value: "Playful & curious", color: SoloraTheme.lavender)
                }
            }

            VStack(alignment: .leading, spacing: 11) {
                Text("Choose a world")
                    .font(.title3.weight(.bold))

                HStack(spacing: 8) {
                    worldChoice("Core room", symbol: "circle.grid.3x3.fill")
                    worldChoice("Career fridge", symbol: "refrigerator.fill")
                    worldChoice("Quest map", symbol: "point.3.connected.trianglepath.dotted")
                }
            }

            VStack(alignment: .leading, spacing: 11) {
                Text("Bring your life in")
                    .font(.title3.weight(.bold))

                HStack(spacing: 8) {
                    source("CV", symbol: "doc.text.fill")
                    source("Calendar", symbol: "calendar")
                }
            }
        }
    }

    private func vibeChoice(_ label: String, value: String, color: Color) -> some View {
        let selected = selectedVibe == value
        return Button {
            withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
                selectedVibe = value
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .overlay {
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.black))
                                .foregroundStyle(SoloraTheme.ink)
                        }
                    }
                Text(label)
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(SoloraTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
            .padding(.horizontal, 12)
            .background(selected ? color.opacity(0.18) : .white.opacity(0.38), in: RoundedRectangle(cornerRadius: 12))
            .soloraHairline(selected ? color.opacity(0.72) : SoloraTheme.ink.opacity(0.08), radius: 12)
        }
        .buttonStyle(SoloraPressButtonStyle(pressedScale: 0.97))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func worldChoice(_ label: String, symbol: String) -> some View {
        let selected = selectedVisualReference == label
        return Button {
            withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
                selectedVisualReference = label
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                Text(label.replacingOccurrences(of: "Career ", with: ""))
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? SoloraTheme.cream : SoloraTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(selected ? SoloraTheme.ink : .white.opacity(0.38), in: RoundedRectangle(cornerRadius: 11))
            .soloraHairline(selected ? SoloraTheme.ink : SoloraTheme.ink.opacity(0.08), radius: 11)
        }
        .buttonStyle(SoloraPressButtonStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func source(_ title: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(SoloraTheme.coral)
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.bold))
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.weight(.black))
                .foregroundStyle(SoloraTheme.moss)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 11))
        .soloraHairline(radius: 11)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), demo connected")
    }

    private func runBrandSequence() {
        brandTask?.cancel()
        guard !reduceMotion else {
            resolvedBrand = true
            showsSetup = true
            return
        }

        brandTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(950))
            guard !Task.isCancelled else { return }
            withAnimation(SoloraMotion.spatial) { resolvedBrand = true }

            try? await Task.sleep(for: .milliseconds(560))
            guard !Task.isCancelled else { return }
            withAnimation(SoloraMotion.reveal) { showsSetup = true }
        }
    }
}
