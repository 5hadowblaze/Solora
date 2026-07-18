import GoogleSignInSwift
import SwiftUI

struct AuthenticationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var session: AuthenticationSession
    @State private var orbIsAlive = false

    var body: some View {
        ZStack {
            SoloraTheme.cream.ignoresSafeArea()

            Circle()
                .fill(SoloraTheme.gold.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 48)
                .offset(x: 120, y: -260)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                Spacer(minLength: 32)

                VStack(spacing: 24) {
                    ZStack {
                        SoloraOrbView(
                            size: 132,
                            color: SoloraTheme.coral,
                            isAlive: orbIsAlive,
                            showsHalo: true
                        )

                        Image(systemName: "sparkles")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 12) {
                        Text("Welcome to Solora")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)

                        Text("Turn the moments that shape your career into a world you can use.")
                            .font(.body.weight(.medium))
                            .foregroundStyle(SoloraTheme.ink.opacity(0.68))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                }

                Spacer(minLength: 40)

                VStack(spacing: 16) {
                    GoogleSignInButton(viewModel: googleButtonModel) {
                        Task { await session.signInWithGoogle() }
                    }
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(session.isSigningIn)
                    .accessibilityHint("Signs in securely using your Google account")

                    if session.isSigningIn {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(SoloraTheme.coral)
                            Text("Opening Google…")
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.64))
                        .transition(.opacity)
                    } else if let errorMessage = session.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(SoloraTheme.coral)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    Label("Your memories stay private to your account", systemImage: "lock.fill")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                }
                .padding(20)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(SoloraTheme.ink.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: SoloraTheme.coral.opacity(0.12), radius: 24, y: 12)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .foregroundStyle(SoloraTheme.ink)
        }
        .animation(reduceMotion ? nil : SoloraMotion.quick, value: session.isSigningIn)
        .animation(reduceMotion ? nil : SoloraMotion.quick, value: session.errorMessage)
        .onAppear {
            guard !orbIsAlive else { return }
            withAnimation(reduceMotion ? nil : SoloraMotion.spatial) {
                orbIsAlive = true
            }
        }
    }

    private var googleButtonModel: GoogleSignInButtonViewModel {
        let model = GoogleSignInButtonViewModel(scheme: .light, style: .wide, state: session.isSigningIn ? .disabled : .normal)
        return model
    }
}

struct AuthenticationLoadingView: View {
    var body: some View {
        ZStack {
            SoloraTheme.cream.ignoresSafeArea()
            VStack(spacing: 16) {
                SoloraOrbView(size: 72, color: SoloraTheme.coral, isAlive: true, showsHalo: true)
                ProgressView("Opening your world…")
                    .font(.footnote.weight(.semibold))
                    .tint(SoloraTheme.coral)
            }
            .foregroundStyle(SoloraTheme.ink)
        }
    }
}
