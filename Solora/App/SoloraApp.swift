import SwiftUI
import FirebaseAppCheck
import FirebaseCore

@main
struct SoloraApp: App {
    @StateObject private var authenticationSession: AuthenticationSession

    init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            #if DEBUG
            AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
            #else
            AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
            #endif
            FirebaseApp.configure()
        }

        let arguments = ProcessInfo.processInfo.arguments
        let bypassesAuthentication = arguments.contains("-skipOnboarding")
            || arguments.contains("-skipAuthentication")
            || arguments.contains("-rehearseOnboarding")
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
    @AppStorage("solora.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private let skipsOnboarding = ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
    private let rehearsesOnboarding = ProcessInfo.processInfo.arguments.contains("-rehearseOnboarding")
    @State private var finishedRehearsal = false
    @State private var selectedVibe = "Warm & reflective"
    @State private var selectedVisualReference = "Core room"

    var body: some View {
        Group {
            if presentsOnboarding {
                SoloraOnboarding { vibe, visualReference in
                    selectedVibe = vibe
                    selectedVisualReference = visualReference
                    withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.reveal) {
                        if !rehearsesOnboarding {
                            hasCompletedOnboarding = true
                        } else {
                            finishedRehearsal = true
                        }
                    }
                }
                .transition(.opacity)
            } else {
                authenticatedExperience
                    .transition(reduceMotion ? .opacity : .soloraReveal)
            }
        }
    }

    private var presentsOnboarding: Bool {
        !skipsOnboarding
            && (rehearsesOnboarding ? !finishedRehearsal : !hasCompletedOnboarding)
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
