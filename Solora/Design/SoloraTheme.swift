import SwiftUI

enum SoloraTheme {
    static let coral = Color(red: 0.851, green: 0.310, blue: 0.271)
    static let cream = Color(red: 0.980, green: 0.941, blue: 0.859)
    static let paper = Color(red: 0.969, green: 0.949, blue: 0.910)
    static let ink = Color(red: 0.110, green: 0.090, blue: 0.122)
    static let gold = Color(red: 0.922, green: 0.682, blue: 0.251)
    static let lavender = Color(red: 0.714, green: 0.620, blue: 0.824)
    static let plum = Color(red: 0.420, green: 0.255, blue: 0.337)
    static let moss = Color(red: 0.420, green: 0.475, blue: 0.310)
    static let fog = Color(red: 0.902, green: 0.859, blue: 0.788)

    static let compactRadius: CGFloat = 12
    static let cardRadius: CGFloat = 16

    static let orbColors: [Color] = [gold, coral, lavender, moss, cream]
}

struct SoloraHairline: ViewModifier {
    var color: Color = SoloraTheme.ink.opacity(0.10)
    var radius: CGFloat = SoloraTheme.cardRadius

    func body(content: Content) -> some View {
        content.overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(color, lineWidth: 1)
        }
    }
}

extension View {
    func soloraHairline(
        _ color: Color = SoloraTheme.ink.opacity(0.10),
        radius: CGFloat = SoloraTheme.cardRadius
    ) -> some View {
        modifier(SoloraHairline(color: color, radius: radius))
    }
}
