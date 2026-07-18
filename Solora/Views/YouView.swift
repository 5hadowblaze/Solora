import SwiftUI

struct YouView: View {
    let vibe: String
    let visualReference: String
    let authenticatedUser: AuthenticatedUser
    let signOut: () -> Void

    @State private var calendarOn = true
    @State private var cvOn = true

    init(
        vibe: String = "Warm & reflective",
        visualReference: String = "Core room",
        authenticatedUser: AuthenticatedUser = .demo,
        signOut: @escaping () -> Void = {}
    ) {
        self.vibe = vibe
        self.visualReference = visualReference
        self.authenticatedUser = authenticatedUser
        self.signOut = signOut
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.paper.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        profile
                            .soloraEntrance()

                        sourceSection
                            .soloraEntrance(index: 1)

                        preferenceSection
                            .soloraEntrance(index: 2)

                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                Text("Private by default")
                            }
                            Spacer()
                            Button("Sign out", action: signOut)
                                .foregroundStyle(SoloraTheme.coral)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.46))
                        .padding(.horizontal, 4)
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var profile: some View {
        HStack(spacing: 16) {
            Group {
                if let photoURL = authenticatedUser.photoURL {
                    AsyncImage(url: photoURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        avatarFallback
                    }
                } else {
                    avatarFallback
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(authenticatedUser.firstName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(authenticatedUser.email ?? "5 memories · 8 threads")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.50))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(SoloraTheme.ink)
        .padding(.top, 4)
    }

    private var avatarFallback: some View {
        ZStack {
            Circle().fill(SoloraTheme.coral)
            Circle()
                .stroke(SoloraTheme.gold, lineWidth: 5)
                .padding(7)
            Text(authenticatedUser.initials)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(SoloraTheme.cream)
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sources")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.52))

            VStack(spacing: 0) {
                sourceRow("Master CV", symbol: "doc.text.fill", tint: SoloraTheme.coral, isOn: $cvOn)
                Divider().padding(.leading, 56)
                sourceRow("Calendar", symbol: "calendar", tint: SoloraTheme.gold, isOn: $calendarOn)
            }
            .background(.white.opacity(0.50), in: RoundedRectangle(cornerRadius: 14))
            .soloraHairline(radius: 14)
        }
    }

    private var preferenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Solora")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.52))

            VStack(spacing: 0) {
                preferenceRow("Energy", value: vibe, symbol: "circle.lefthalf.filled")
                Divider().padding(.leading, 56)
                preferenceRow("World", value: worldStyle, symbol: "circle.grid.3x3.fill")
                Divider().padding(.leading, 56)
                preferenceRow("Privacy", value: "Only you", symbol: "lock.fill")
            }
            .background(.white.opacity(0.50), in: RoundedRectangle(cornerRadius: 14))
            .soloraHairline(radius: 14)
        }
    }

    private var worldStyle: String {
        if visualReference.localizedCaseInsensitiveContains("fridge") { return "Career fridge" }
        if visualReference.localizedCaseInsensitiveContains("map") { return "Constellation" }
        return "Core room"
    }

    private func sourceRow(
        _ title: String,
        symbol: String,
        tint: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(SoloraTheme.moss)
        }
        .foregroundStyle(SoloraTheme.ink)
        .padding(.horizontal, 14)
        .frame(height: 58)
    }

    private func preferenceRow(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SoloraTheme.coral)
                .frame(width: 30)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.46))
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.24))
        }
        .foregroundStyle(SoloraTheme.ink)
        .padding(.horizontal, 14)
        .frame(height: 58)
    }
}
