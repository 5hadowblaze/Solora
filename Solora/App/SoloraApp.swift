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

    var body: some View {
        Group {
            if hasEntered {
                RootTabView(container: .demo)
            } else {
                SoloraOnboarding {
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
    @State private var cvReady = true
    @State private var calendarReady = true

    let enter: () -> Void

    private let ink = Color(red: 0.13, green: 0.08, blue: 0.07)
    private let cream = Color(red: 0.99, green: 0.94, blue: 0.84)
    private let coral = Color(red: 0.86, green: 0.27, blue: 0.20)
    private let gold = Color(red: 0.82, green: 0.57, blue: 0.18)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 20)

                Spacer(minLength: 20)

                brandMoment

                Spacer(minLength: 24)

                if showSetup {
                    setup
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: showSetup ? 16 : 44)

                Button(action: enter) {
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
                .padding(.bottom, 18)
            }
        }
        .foregroundStyle(ink)
        .onAppear(perform: runBrandSequence)
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
        VStack(alignment: .leading, spacing: 20) {
            Text("Set the tone")
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

            HStack(spacing: 12) {
                sourceToggle(title: "CV", subtitle: "Demo ready", isOn: $cvReady)
                sourceToggle(title: "Calendar", subtitle: "Demo ready", isOn: $calendarReady)
            }
        }
        .padding(.horizontal, 24)
    }

    private func sourceToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                        .foregroundStyle(isOn.wrappedValue ? gold : ink.opacity(0.42))
                }
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(ink.opacity(0.64))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(ink.opacity(0.045))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ink.opacity(0.14), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityValue(isOn.wrappedValue ? "Selected" : "Not selected")
    }

    private func runBrandSequence() {
        guard !reduceMotion else {
            revealSolora = true
            showSetup = true
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.easeInOut(duration: 0.28)) { revealSolora = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.62) {
            withAnimation(.easeOut(duration: 0.28)) { showSetup = true }
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
