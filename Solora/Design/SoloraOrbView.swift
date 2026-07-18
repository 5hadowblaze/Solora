import SwiftUI

struct SoloraOrbView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var size: CGFloat = 96
    var color: Color = SoloraTheme.gold
    var isAlive = false
    var showsHalo = false

    var body: some View {
        Group {
            if isAlive && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    orb(at: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                orb(at: 0)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Glowing Solora orb")
        .accessibilityHint("A visual marker in your personal world")
    }

    private func orb(at time: TimeInterval) -> some View {
        let phase = time.truncatingRemainder(dividingBy: 20)
        let breath = 1 + sin(phase * 0.9) * 0.018
        let highlightX = cos(phase * 0.72) * size * 0.06
        let highlightY = sin(phase * 0.58) * size * 0.045

        return ZStack {
            if showsHalo {
                Circle()
                    .trim(from: 0.06, to: 0.72)
                    .stroke(
                        AngularGradient(
                            colors: [color.opacity(0), color.opacity(0.7), .white.opacity(0.8), color.opacity(0)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: max(1.5, size * 0.018), lineCap: .round)
                    )
                    .padding(-size * 0.11)
                    .rotationEffect(.degrees(phase * 13))
                    .opacity(0.72)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.98), color, color.opacity(0.35)],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: size * 0.72
                    )
                )

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            .white.opacity(0.42),
                            color.opacity(0.05),
                            SoloraTheme.coral.opacity(0.28),
                            color.opacity(0.62),
                            .white.opacity(0.42)
                        ],
                        center: .center
                    )
                )
                .rotationEffect(.degrees(phase * -7))
                .opacity(0.62)
                .mask(Circle().padding(size * 0.045))

            Circle()
                .fill(.white.opacity(0.72))
                .frame(width: size * 0.24, height: size * 0.17)
                .blur(radius: max(1, size * 0.035))
                .offset(x: -size * 0.2 + highlightX, y: -size * 0.23 + highlightY)

            Circle()
                .stroke(.white.opacity(0.55), lineWidth: max(1, size * 0.012))
                .padding(size * 0.025)
        }
        .scaleEffect(breath)
        .shadow(color: color.opacity(0.28), radius: size * 0.16, y: size * 0.08)
    }
}
