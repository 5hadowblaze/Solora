import FirebaseCore
import Foundation
import GoogleSignIn
import UIKit

struct GoogleCalendarCredential: Sendable {
    let accessToken: String
    let accountEmail: String
}

enum GoogleCalendarAuthorizationState: Equatable, Sendable {
    case disconnected
    case connected(accountEmail: String)
    case needsAttention(message: String)
}

enum GoogleCalendarAuthorizationError: LocalizedError, Equatable {
    case cancelled
    case missingConfiguration
    case missingPresenter
    case missingAccount
    case accountMismatch
    case permissionRequired
    case authorizationFailed

    var errorDescription: String? {
        switch self {
        case .cancelled:
            "Calendar connection was cancelled. Nothing was shared."
        case .missingConfiguration:
            "Google Sign-In is not configured for this Firebase app."
        case .missingPresenter:
            "Solora couldn't open Google's permission screen. Please try again."
        case .missingAccount:
            "Solora couldn't identify the connected Google account."
        case .accountMismatch:
            "Choose the same Google account you use for Solora."
        case .permissionRequired:
            "Calendar permission was not granted. Nothing was imported."
        case .authorizationFailed:
            "Solora couldn't connect to Google Calendar. Please try again."
        }
    }
}

@MainActor
final class GoogleCalendarAuthorization {
    static let eventsReadOnlyScope = "https://www.googleapis.com/auth/calendar.events.readonly"

    func restoredState(expectedEmail: String?) async -> GoogleCalendarAuthorizationState {
        do {
            guard let user = try await restoredUser() else { return .disconnected }
            let email = try validatedEmail(for: user, expectedEmail: expectedEmail)
            guard user.grantedScopes?.contains(Self.eventsReadOnlyScope) == true else {
                return .disconnected
            }
            return .connected(accountEmail: email)
        } catch GoogleCalendarAuthorizationError.accountMismatch {
            return .needsAttention(message: GoogleCalendarAuthorizationError.accountMismatch.localizedDescription)
        } catch {
            return .needsAttention(message: "Google Calendar access needs to be reconnected.")
        }
    }

    func connect(expectedEmail: String?) async throws -> GoogleCalendarCredential {
        let user = try await userForInteractiveConnection()
        _ = try validatedEmail(for: user, expectedEmail: expectedEmail)

        let authorisedUser: GIDGoogleUser
        if user.grantedScopes?.contains(Self.eventsReadOnlyScope) == true {
            authorisedUser = user
        } else {
            guard let presenter = Self.presentingViewController else {
                throw GoogleCalendarAuthorizationError.missingPresenter
            }
            do {
                let result = try await user.addScopes([Self.eventsReadOnlyScope], presenting: presenter)
                authorisedUser = result.user
            } catch let error as GIDSignInError where error.code == .canceled {
                throw GoogleCalendarAuthorizationError.cancelled
            } catch {
                throw GoogleCalendarAuthorizationError.authorizationFailed
            }
        }

        guard authorisedUser.grantedScopes?.contains(Self.eventsReadOnlyScope) == true else {
            throw GoogleCalendarAuthorizationError.permissionRequired
        }
        return try await credential(for: authorisedUser, expectedEmail: expectedEmail)
    }

    func credentialForRequest(expectedEmail: String?) async throws -> GoogleCalendarCredential {
        guard let user = try await restoredUser() else {
            throw GoogleCalendarAuthorizationError.permissionRequired
        }
        guard user.grantedScopes?.contains(Self.eventsReadOnlyScope) == true else {
            throw GoogleCalendarAuthorizationError.permissionRequired
        }
        return try await credential(for: user, expectedEmail: expectedEmail)
    }

    func disconnect() async throws {
        do {
            try await GIDSignIn.sharedInstance.disconnect()
        } catch {
            throw GoogleCalendarAuthorizationError.authorizationFailed
        }
    }

    private func credential(
        for user: GIDGoogleUser,
        expectedEmail: String?
    ) async throws -> GoogleCalendarCredential {
        let refreshed: GIDGoogleUser
        do {
            refreshed = try await user.refreshTokensIfNeeded()
        } catch {
            throw GoogleCalendarAuthorizationError.permissionRequired
        }
        let email = try validatedEmail(for: refreshed, expectedEmail: expectedEmail)
        return GoogleCalendarCredential(
            accessToken: refreshed.accessToken.tokenString,
            accountEmail: email
        )
    }

    private func restoredUser() async throws -> GIDGoogleUser? {
        if let currentUser = GIDSignIn.sharedInstance.currentUser { return currentUser }
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() else { return nil }
        do {
            return try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        } catch {
            throw GoogleCalendarAuthorizationError.permissionRequired
        }
    }

    private func userForInteractiveConnection() async throws -> GIDGoogleUser {
        if let restored = try? await restoredUser() { return restored }
        guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
            throw GoogleCalendarAuthorizationError.missingConfiguration
        }
        guard let presenter = Self.presentingViewController else {
            throw GoogleCalendarAuthorizationError.missingPresenter
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            return try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter).user
        } catch let error as GIDSignInError where error.code == .canceled {
            throw GoogleCalendarAuthorizationError.cancelled
        } catch {
            throw GoogleCalendarAuthorizationError.authorizationFailed
        }
    }

    private func validatedEmail(for user: GIDGoogleUser, expectedEmail: String?) throws -> String {
        guard let email = user.profile?.email, !email.isEmpty else {
            throw GoogleCalendarAuthorizationError.missingAccount
        }
        if let expectedEmail,
           !expectedEmail.isEmpty,
           email.caseInsensitiveCompare(expectedEmail) != .orderedSame {
            GIDSignIn.sharedInstance.signOut()
            throw GoogleCalendarAuthorizationError.accountMismatch
        }
        return email
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
}
