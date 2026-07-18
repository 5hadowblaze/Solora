import SwiftUI

enum SoloraMotion {
    /// Fast feedback for controls. The strong ease-out front-loads the response.
    static let quick = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.16)

    /// Small state changes that may be interrupted by another tap.
    static let responsive = Animation.spring(duration: 0.26, bounce: 0.08)

    /// Spatial changes where preserving velocity makes the interface feel continuous.
    static let spatial = Animation.spring(duration: 0.42, bounce: 0.12)

    /// Calm entrance motion for infrequent, explanatory content.
    static let reveal = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.34)
}

struct SoloraPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var pressedScale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : pressedScale)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : SoloraMotion.quick, value: configuration.isPressed)
    }
}

private struct SoloraEntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    let index: Int
    let distance: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: reduceMotion || isVisible ? 0 : distance)
            .onAppear {
                guard !isVisible else { return }
                let delay = min(Double(index) * 0.045, 0.22)
                withAnimation((reduceMotion ? .easeOut(duration: 0.18) : SoloraMotion.reveal).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

private struct SoloraBlurTransitionModifier: ViewModifier {
    let opacity: Double
    let scale: CGFloat
    let offset: CGFloat
    let blur: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(y: offset)
            .blur(radius: blur)
    }
}

extension View {
    func soloraEntrance(index: Int = 0, distance: CGFloat = 10) -> some View {
        modifier(SoloraEntranceModifier(index: index, distance: distance))
    }
}

extension AnyTransition {
    static var soloraReveal: AnyTransition {
        .modifier(
            active: SoloraBlurTransitionModifier(opacity: 0, scale: 0.985, offset: 10, blur: 2.5),
            identity: SoloraBlurTransitionModifier(opacity: 1, scale: 1, offset: 0, blur: 0)
        )
    }
}
