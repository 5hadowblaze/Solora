import FirebaseFirestore
import Foundation
import Combine

enum CalendarSourceStatus: Equatable {
    case checking
    case notConnected
    case connected(accountEmail: String)
    case needsAttention(message: String)

    var label: String {
        switch self {
        case .checking: "Checking…"
        case .notConnected: "Not connected"
        case .connected: "Connected"
        case .needsAttention: "Needs attention"
        }
    }
}

enum CalendarMemorySaveResult: Equatable {
    case saved
    case alreadySaved
}

@MainActor
final class CalendarSourceStore: ObservableObject {
    @Published private(set) var status: CalendarSourceStatus = .checking
    @Published private(set) var events: [CalendarEventCandidate] = []
    @Published private(set) var isLoadingEvents = false
    @Published private(set) var hasLoadedEvents = false
    @Published private(set) var lastChecked: Date?
    @Published var errorMessage: String?

    private let userID: String
    private let expectedEmail: String?
    private let authorization = GoogleCalendarAuthorization()
    private let client = GoogleCalendarClient()
    private var skippedEventIDs: Set<String> = []

    init(userID: String, expectedEmail: String?) {
        self.userID = userID
        self.expectedEmail = expectedEmail
        if userID == AuthenticatedUser.demo.id {
            status = .notConnected
        }
    }

    func restoreConnectionState() async {
        guard userID != AuthenticatedUser.demo.id else {
            status = .notConnected
            return
        }
        status = .checking
        let restored = await authorization.restoredState(expectedEmail: expectedEmail)
        apply(restored)
    }

    func connectAndReview() async {
        errorMessage = nil
        isLoadingEvents = true
        defer { isLoadingEvents = false }

        do {
            let credential = try await authorization.connect(expectedEmail: expectedEmail)
            status = .connected(accountEmail: credential.accountEmail)
            try await loadEvents(accessToken: credential.accessToken)
        } catch {
            handle(error)
        }
    }

    func refreshEvents() async {
        errorMessage = nil
        isLoadingEvents = true
        defer { isLoadingEvents = false }

        do {
            let credential = try await authorization.credentialForRequest(expectedEmail: expectedEmail)
            status = .connected(accountEmail: credential.accountEmail)
            try await loadEvents(accessToken: credential.accessToken)
        } catch {
            handle(error)
        }
    }

    func skip(_ event: CalendarEventCandidate) {
        skippedEventIDs.insert(event.id)
        events.removeAll { $0.id == event.id }
    }

    func saveMemory(
        from event: CalendarEventCandidate,
        reflection: String
    ) async throws -> CalendarMemorySaveResult {
        guard let moment = CalendarMemoryMapper.moment(
            from: event,
            reflection: reflection,
            userID: userID
        ) else {
            throw CalendarReviewError.reflectionRequired
        }

        let document = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("wins")
            .document(moment.id)

        if let snapshot = try? await document.getDocument(), snapshot.exists {
            events.removeAll { $0.id == event.id }
            return .alreadySaved
        }

        do {
            try FirebaseMomentRepository.saveMoment(moment, userID: userID) { [weak self] message in
                guard let message else { return }
                Task { @MainActor [weak self] in
                    self?.errorMessage = message
                    if self?.events.contains(where: { $0.id == event.id }) == false {
                        self?.events.append(event)
                        self?.events.sort { $0.startDate > $1.startDate }
                    }
                }
            }
            events.removeAll { $0.id == event.id }
            return .saved
        } catch {
            throw CalendarReviewError.saveFailed(
                (error as? LocalizedError)?.errorDescription
                    ?? "This memory could not be saved. Please try again."
            )
        }
    }

    func disconnectAndRevoke() async {
        errorMessage = nil
        do {
            try await authorization.disconnect()
            events = []
            skippedEventIDs = []
            lastChecked = nil
            hasLoadedEvents = false
            status = .notConnected
        } catch {
            errorMessage = error.localizedDescription
            status = .needsAttention(message: "Google access could not be revoked.")
        }
    }

    private func loadEvents(accessToken: String) async throws {
        let fetched = try await client.completedEvents(accessToken: accessToken)
        events = fetched.filter { !skippedEventIDs.contains($0.id) }
        hasLoadedEvents = true
        lastChecked = .now
    }

    private func apply(_ state: GoogleCalendarAuthorizationState) {
        switch state {
        case .disconnected:
            status = .notConnected
        case .connected(let accountEmail):
            status = .connected(accountEmail: accountEmail)
        case .needsAttention(let message):
            status = .needsAttention(message: message)
        }
    }

    private func handle(_ error: Error) {
        errorMessage = error.localizedDescription
        let clientError = error as? GoogleCalendarClientError
        let authorizationError = error as? GoogleCalendarAuthorizationError

        if clientError == .permissionRequired
            || authorizationError == .permissionRequired
            || authorizationError == .accountMismatch {
            status = .needsAttention(message: error.localizedDescription)
        } else if status == .checking {
            status = .notConnected
        }
    }
}

enum CalendarReviewError: LocalizedError {
    case reflectionRequired
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .reflectionRequired:
            "Write one thought about what changed before saving."
        case .saveFailed(let message):
            message
        }
    }
}
