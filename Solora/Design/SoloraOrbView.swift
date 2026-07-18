import SwiftUI

struct SoloraOrbView: View {
    var size: CGFloat = 96
    var color: Color = SoloraTheme.gold

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [.white.opacity(0.95), color, color.opacity(0.28)], center: .topLeading, startRadius: 2, endRadius: size / 1.7))
            .frame(width: size, height: size)
            .accessibilityElement()
            .accessibilityLabel("Glowing orb")
            .accessibilityHint("A visual marker in your personal world")
    }
}
