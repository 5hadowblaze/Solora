import SwiftUI

struct SoloraOnboardingGlassOrb: View {
    let size: CGFloat
    let color: Color
    var isAlive = false
    var showsHalo = false

    var body: some View {
        SoloraOrbView(
            size: size,
            color: color,
            isAlive: isAlive,
            showsHalo: showsHalo
        )
        .background(.ultraThinMaterial, in: Circle())
        .overlay {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.88), .white.opacity(0.12), color.opacity(0.32)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1, size * 0.012)
                )
                .padding(size * 0.035)
                .allowsHitTesting(false)
        }
    }
}

struct SoloraKineticOrbField: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let seeds: [SoloraOnboardingOrbSeed]

    var body: some View {
        GeometryReader { proxy in
            Group {
                if reduceMotion {
                    field(in: proxy.size, time: 0)
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        field(in: proxy.size, time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func field(in size: CGSize, time: TimeInterval) -> some View {
        ZStack {
            ForEach(seeds.sorted { $0.depth < $1.depth }) { seed in
                let cycle = reduceMotion
                    ? 0.72
                    : (time * (0.085 + seed.depth * 0.018) + seed.phase / 6.28)
                        .truncatingRemainder(dividingBy: 1)
                let perspective = pow(cycle, 1.55)
                let reach = 0.10 + perspective * 1.18
                let centerX = size.width * 0.5
                let centerY = size.height * 0.34
                let destinationX = size.width * seed.x
                let destinationY = size.height * seed.y
                let fadeIn = min(1, cycle / 0.10)
                let fadeOut = min(1, (1 - cycle) / 0.16)
                let visibility = reduceMotion ? 0.78 : max(0, min(fadeIn, fadeOut))

                SoloraOnboardingGlassOrb(
                    size: seed.size,
                    color: seed.color
                )
                .scaleEffect((0.16 + perspective * (0.92 + seed.depth * 0.34)))
                .opacity(visibility * (0.56 + seed.depth * 0.42))
                .blur(radius: cycle < 0.14 ? 1.8 : 0)
                .position(
                    x: centerX + (destinationX - centerX) * reach,
                    y: centerY + (destinationY - centerY) * reach
                )
            }
        }
    }
}

struct SoloraOnboardingProgressHeader: View {
    let step: SoloraOnboardingStep
    let usesLightForeground: Bool
    let canGoBack: Bool
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 44, height: 44)
                    .background(foreground.opacity(0.08), in: Circle())
            }
            .buttonStyle(SoloraPressButtonStyle())
            .foregroundStyle(foreground)
            .opacity(canGoBack ? 1 : 0)
            .disabled(!canGoBack)
            .accessibilityLabel("Back")

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(foreground.opacity(0.14))
                    Capsule()
                        .fill(foreground.opacity(0.84))
                        .frame(width: proxy.size.width * step.progress)
                }
            }
            .frame(height: 4)
            .accessibilityElement()
            .accessibilityLabel("Onboarding progress")
            .accessibilityValue("Step \(step.rawValue + 1) of \(SoloraOnboardingStep.allCases.count)")

            Text("\(step.rawValue + 1)/\(SoloraOnboardingStep.allCases.count)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(foreground.opacity(0.58))
                .frame(width: 30, alignment: .trailing)
        }
        .frame(height: 44)
    }

    private var foreground: Color {
        usesLightForeground ? SoloraTheme.cream : SoloraTheme.ink
    }
}

struct SoloraOnboardingPrimaryButton: View {
    let title: String
    var detail: String?
    var usesLightStyle = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.bold))
                    if let detail {
                        Text(detail)
                            .font(.caption.weight(.medium))
                            .opacity(0.62)
                    }
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(usesLightStyle ? SoloraTheme.ink : SoloraTheme.cream)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: detail == nil ? 56 : 64)
            .background(
                usesLightStyle ? SoloraTheme.cream : SoloraTheme.ink,
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.white.opacity(usesLightStyle ? 0.30 : 0.10), lineWidth: 1)
            }
        }
        .buttonStyle(SoloraPressButtonStyle())
    }
}

struct SoloraOnboardingSourceCard: View {
    let source: SoloraOnboardingSource
    let isIncluded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(source.tint.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: source.symbol)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(source.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(source.title)
                        .font(.body.weight(.bold))
                    Text(source.subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.52))
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 5) {
                    Image(systemName: isIncluded ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isIncluded ? SoloraTheme.moss : SoloraTheme.ink.opacity(0.32))
                    Text(isIncluded ? (source == .chatGPT ? "Imported" : "Included") : (source == .chatGPT ? "Optional" : "Add"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.44))
                }
            }
            .foregroundStyle(SoloraTheme.ink)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 82)
            .background(
                isIncluded ? source.tint.opacity(0.10) : Color.white.opacity(0.48),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .soloraHairline(isIncluded ? source.tint.opacity(0.46) : SoloraTheme.ink.opacity(0.08), radius: 18)
        }
        .buttonStyle(SoloraPressButtonStyle(pressedScale: 0.985))
        .accessibilityLabel("\(source.title), \(isIncluded ? "included" : "not included")")
        .accessibilityHint(source == .chatGPT ? "Opens the manual ChatGPT handoff" : "Includes or removes this source preference")
    }
}

struct SoloraOnboardingChoicePill: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(SoloraTheme.ink)
                        }
                    }
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
            }
            .foregroundStyle(SoloraTheme.ink)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                isSelected ? color.opacity(0.18) : Color.white.opacity(0.42),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .soloraHairline(isSelected ? color.opacity(0.60) : SoloraTheme.ink.opacity(0.08), radius: 14)
        }
        .buttonStyle(SoloraPressButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct SoloraOnboardingWorldCard: View {
    let title: String
    let symbol: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SoloraOnboardingGlassOrb(size: 34, color: color)
                        .accessibilityHidden(true)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SoloraTheme.cream)
                    }
                }
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .opacity(0.62)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
            }
            .foregroundStyle(isSelected ? SoloraTheme.cream : SoloraTheme.ink)
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
            .background(
                isSelected ? SoloraTheme.ink : Color.white.opacity(0.42),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .soloraHairline(isSelected ? SoloraTheme.ink : SoloraTheme.ink.opacity(0.08), radius: 18)
        }
        .buttonStyle(SoloraPressButtonStyle(pressedScale: 0.98))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
