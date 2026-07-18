@preconcurrency import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class AuthenticationSession: ObservableObject {
    enum State: Equatable {
        case checking
        case signedOut
        case signedIn(AuthenticatedUser)
    }

    @Published private(set) var state: State
    @Published private(set) var isSigningIn = false
    @Published var errorMessage: String?

    private var authListener: AuthStateDidChangeListenerHandle?
    private let bypassesAuthentication: Bool

    init(bypassesAuthentication: Bool = false) {
        self.bypassesAuthentication = bypassesAuthentication
        state = bypassesAuthentication ? .signedIn(.demo) : .checking

        guard !bypassesAuthentication else { return }

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let snapshot = user.map(AuthenticatedUser.init(firebaseUser:))
            Task { @MainActor [weak self] in
                self?.state = snapshot.map(State.signedIn) ?? .signedOut
            }
        }
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    func signInWithGoogle() async {
        guard !isSigningIn else { return }
        errorMessage = nil
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
                throw AuthenticationError.missingGoogleConfiguration
            }
            guard let presentingViewController = Self.presentingViewController else {
                throw AuthenticationError.missingPresentingViewController
            }

            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthenticationError.missingIDToken
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            _ = try await Auth.auth().signIn(with: credential)
        } catch let error as GIDSignInError where error.code == .canceled {
            // Closing Google's account picker is an intentional cancellation, not an error.
        } catch {
            errorMessage = Self.userFacingMessage(for: error)
        }
    }

    func signOut() {
        guard !bypassesAuthentication else { return }
        errorMessage = nil

        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
        } catch {
            errorMessage = Self.userFacingMessage(for: error)
        }
    }

    func handleOpenURL(_ url: URL) {
        _ = GIDSignIn.sharedInstance.handle(url)
    }

    private static var presentingViewController: UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var controller = windowScene?.windows.first(where: \.isKeyWindow)?.rootViewController

        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }

    private static func userFacingMessage(for error: Error) -> String {
        if let error = error as? AuthenticationError {
            return error.localizedDescription
        }

        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain,
           let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .networkError:
                return "We couldn't reach Google. Check your connection and try again."
            case .accountExistsWithDifferentCredential:
                return "An account already exists for this email with another sign-in method."
            case .userDisabled:
                return "This account has been disabled."
            default:
                break
            }
        }
        return "Google sign-in didn't complete. Please try again."
    }
}

private extension AuthenticatedUser {
    init(firebaseUser: FirebaseAuth.User) {
        id = firebaseUser.uid
        displayName = firebaseUser.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty ?? firebaseUser.email?.components(separatedBy: "@").first ?? "Solora member"
        email = firebaseUser.email
        photoURL = firebaseUser.photoURL
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private enum AuthenticationError: LocalizedError {
    case missingGoogleConfiguration
    case missingPresentingViewController
    case missingIDToken

    var errorDescription: String? {
        switch self {
        case .missingGoogleConfiguration:
            return "Google sign-in is not configured for this Firebase app yet."
        case .missingPresentingViewController:
            return "Solora couldn't open Google's sign-in window. Please try again."
        case .missingIDToken:
            return "Google didn't return a valid identity token. Please try again."
        }
    }
}
