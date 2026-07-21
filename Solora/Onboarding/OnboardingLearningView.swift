import SwiftUI
import UIKit

struct SoloraOnboardingLearningView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let sources: [SoloraOnboardingSource]
    let onFinished: () -> Void

    @State private var phase: SoloraLearningPhase = .gathering
    @State private var sequenceTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            SoloraLearningBackdrop(phase: phase, reduceMotion: reduceMotion)

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                SoloraFormationField(
                    phase: phase,
                    sources: sources,
                    reduceMotion: reduceMotion
                )
                .frame(height: 330)

                VStack(spacing: 12) {
                    Text(phase.title)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .id("title-\(phase.rawValue)")
                        .transition(reduceMotion ? .opacity : .soloraReveal)

                    Text(phase.detail)
                        .font(.body.weight(.medium))
                        .foregroundStyle(SoloraTheme.cream.opacity(0.62))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .id("detail-\(phase.rawValue)")
                        .transition(.opacity)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(SoloraTheme.cream.opacity(0.12))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [SoloraTheme.coral, SoloraTheme.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: proxy.size.width * phase.progress)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 12)
                    .accessibilityElement()
                    .accessibilityLabel("Learning progress")
                    .accessibilityValue("\(Int(phase.progress * 100)) percent")
                }
                .frame(maxWidth: 340)
                .foregroundStyle(SoloraTheme.cream)
                .animation(reduceMotion ? .easeOut(duration: 0.18) : SoloraMotion.reveal, value: phase)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
        .onAppear(perform: runSequence)
        .onDisappear {
            sequenceTask?.cancel()
            sequenceTask = nil
        }
    }

    private func runSequence() {
        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            if reduceMotion {
                phase = .shaping
                try? await Task.sleep(for: .milliseconds(1_100))
                guard !Task.isCancelled else { return }
                onFinished()
                return
            }

            for nextPhase in SoloraLearningPhase.allCases {
                guard !Task.isCancelled else { return }
                withAnimation(SoloraMotion.reveal) {
                    phase = nextPhase
                }
                UIAccessibility.post(notification: .announcement, argument: nextPhase.title)
                try? await Task.sleep(for: .milliseconds(nextPhase.beatMilliseconds))
            }

            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}

private struct SoloraLearningBackdrop: View {
    let phase: SoloraLearningPhase
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            Group {
                if reduceMotion {
                    backdrop(in: proxy.size, time: 0)
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        backdrop(in: proxy.size, time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func backdrop(in size: CGSize, time: TimeInterval) -> some View {
        let x = 0.46 + sin(time * 0.16) * 0.12
        let y = 0.32 + cos(time * 0.13) * 0.10
        let progress = Double(phase.rawValue) / Double(max(1, SoloraLearningPhase.allCases.count - 1))

        return ZStack {
            LinearGradient(
                stops: [
                    .init(color: SoloraTheme.plum, location: 0),
                    .init(color: SoloraTheme.lavender.opacity(0.94), location: 0.30),
                    .init(color: SoloraTheme.coral.opacity(0.86), location: 0.57),
                    .init(color: SoloraTheme.plum, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    SoloraTheme.cream.opacity(0.48),
                    SoloraTheme.gold.opacity(0.18),
                    .clear
                ],
                center: UnitPoint(x: x, y: y),
                startRadius: 2,
                endRadius: max(size.width, size.height) * 0.66
            )

            RadialGradient(
                colors: [SoloraTheme.cream.opacity(0.52), SoloraTheme.lavender.opacity(0.12), .clear],
                center: UnitPoint(x: 1 - x * 0.48, y: 0.72),
                startRadius: 0,
                endRadius: size.width * 0.86
            )
            .blendMode(.screen)

            Ellipse()
                .fill(SoloraTheme.cream.opacity(0.34))
                .frame(width: size.width * 1.32, height: size.height * 0.28)
                .blur(radius: 30)
                .offset(y: size.height * 0.40 + cos(time * 0.12) * 18)

            LinearGradient(
                colors: [SoloraTheme.ink.opacity(0.10), .clear, SoloraTheme.plum.opacity(0.34)],
                startPoint: .top,
                endPoint: .bottom
            )

            SoloraTheme.cream
                .opacity(phase == .shaping ? 0.18 + progress * 0.12 : 0)
                .animation(.easeInOut(duration: 1.55), value: phase)
        }
    }
}

private struct SoloraFormationField: View {
    let phase: SoloraLearningPhase
    let sources: [SoloraOnboardingSource]
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            Group {
                if reduceMotion {
                    formation(in: proxy.size, time: 0)
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        formation(in: proxy.size, time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your selected sources forming a Solora")
    }

    private func formation(in size: CGSize, time: TimeInterval) -> some View {
        let progress = CGFloat(phase.rawValue) / CGFloat(max(1, SoloraLearningPhase.allCases.count - 1))
        let center = CGPoint(x: size.width / 2, y: size.height * 0.46)
        let visibleSources = sources.isEmpty ? [.cv] : sources
        let radius = 112 - progress * 50

        return ZStack {
            Ellipse()
                .fill(SoloraTheme.coral.opacity(0.15 + Double(progress) * 0.12))
                .frame(width: 210 - progress * 38, height: 58 - progress * 10)
                .blur(radius: 18)
                .position(x: center.x, y: center.y + 100)

            SoloraOnboardingGlassOrb(
                size: 126 + progress * 24,
                color: phase.rawValue >= SoloraLearningPhase.forming.rawValue ? SoloraTheme.gold : SoloraTheme.coral,
                isAlive: true,
                showsHalo: phase.rawValue >= SoloraLearningPhase.connecting.rawValue
            )
            .scaleEffect(x: 1, y: -0.46, anchor: .center)
            .opacity(0.20 + Double(progress) * 0.10)
            .blur(radius: 2.5)
            .mask {
                LinearGradient(
                    colors: [.white.opacity(0.72), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .position(x: center.x, y: center.y + 111 - progress * 10)

            ForEach(Array(visibleSources.enumerated()), id: \.element.id) { index, source in
                let baseAngle = (Double(index) / Double(max(visibleSources.count, 1))) * Double.pi * 2
                let liveAngle = baseAngle + (reduceMotion ? 0 : time * 0.22)
                let x = center.x + cos(liveAngle) * radius
                let y = center.y + sin(liveAngle) * radius * 0.44

                ZStack {
                    SoloraOnboardingGlassOrb(size: 40, color: source.tint)
                    Image(systemName: source.symbol)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SoloraTheme.cream)
                }
                .opacity(phase == .shaping ? 0.34 : 0.92)
                .scaleEffect(phase == .shaping ? 0.72 : 1)
                .position(x: x, y: y)
            }

            SoloraOnboardingGlassOrb(
                size: 126 + progress * 24,
                color: phase.rawValue >= SoloraLearningPhase.forming.rawValue ? SoloraTheme.gold : SoloraTheme.coral,
                isAlive: true,
                showsHalo: phase.rawValue >= SoloraLearningPhase.connecting.rawValue
            )
            .position(x: center.x, y: center.y + 76 - progress * 116)
            .shadow(color: SoloraTheme.coral.opacity(0.20), radius: 34, y: 16)
        }
        .animation(reduceMotion ? .easeOut(duration: 0.18) : SoloraMotion.spatial, value: phase)
    }
}
