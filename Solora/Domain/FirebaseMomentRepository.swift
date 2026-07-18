@preconcurrency import FirebaseFirestore
import Foundation

struct MomentRepositorySnapshot: Sendable {
    let moments: [SoloraMoment]
    let isFromCache: Bool
    let hasPendingWrites: Bool
}

enum MomentRepositoryEvent: Sendable {
    case snapshot(MomentRepositorySnapshot)
    case failure(String)
}

enum FirebaseMomentRepository {
    private static let usersCollection = "users"
    private static let momentsCollection = "wins"

    @discardableResult
    static func observeMoments(
        userID: String,
        onEvent: @escaping (MomentRepositoryEvent) -> Void
    ) -> ListenerRegistration {
        collection(userID: userID)
            .addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
                if let error {
                    onEvent(.failure(userFacingMessage(for: error)))
                    return
                }

                guard let snapshot else {
                    onEvent(.failure("Your lore could not be loaded right now."))
                    return
                }

                let moments = snapshot.documents
                    .compactMap { moment(documentID: $0.documentID, data: $0.data()) }
                    .sorted { $0.date > $1.date }

                onEvent(.snapshot(MomentRepositorySnapshot(
                    moments: moments,
                    isFromCache: snapshot.metadata.isFromCache,
                    hasPendingWrites: snapshot.metadata.hasPendingWrites
                )))
            }
    }

    static func saveMoment(
        _ moment: SoloraMoment,
        userID: String,
        completion: @escaping (String?) -> Void
    ) throws {
        try validate(moment)

        let document = collection(userID: userID).document(moment.id)
        try document.setData(from: FirestoreMomentWrite(moment: moment)) { error in
            completion(error.map(userFacingMessage(for:)))
        }
    }

    static func deleteMoment(
        id: String,
        userID: String,
        completion: @escaping (String?) -> Void
    ) {
        collection(userID: userID).document(id).delete { error in
            completion(error.map(userFacingMessage(for:)))
        }
    }

    static func moment(documentID: String, data: [String: Any]) -> SoloraMoment? {
        guard let title = nonEmptyString(data["title"]) else { return nil }

        let star = data["star"] as? [String: Any]
        let photoPaths = data["photoPaths"] as? [String] ?? []
        let summary = nonEmptyString(data["caption"])
            ?? nonEmptyString(star?["result"])
            ?? "Imported from Career Fridge."
        let date = timestamp(data["occurredAt"])
            ?? timestamp(data["createdAt"])
            ?? timestamp(data["weekOf"])
            ?? .distantPast

        return SoloraMoment(
            id: documentID,
            title: title,
            summary: summary,
            date: date,
            world: WorldKind(rawValue: nonEmptyString(data["world"]) ?? "") ?? .memoryShelves,
            category: nonEmptyString(data["category"]),
            stickerPath: nonEmptyString(data["stickerPath"]),
            photoPaths: Array(photoPaths.prefix(10))
        )
    }

    static func validate(_ moment: SoloraMoment) throws {
        guard !moment.id.isEmpty, moment.id.count <= 128 else {
            throw MomentRepositoryError.invalidIdentifier
        }
        guard !moment.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              moment.title.count <= 120 else {
            throw MomentRepositoryError.invalidTitle
        }
        guard !moment.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              moment.summary.count <= 2_000 else {
            throw MomentRepositoryError.invalidSummary
        }
        guard moment.category?.count ?? 0 <= 40,
              moment.stickerPath?.count ?? 0 <= 512,
              moment.photoPaths.count <= 10,
              moment.photoPaths.allSatisfy({ $0.count <= 512 }) else {
            throw MomentRepositoryError.invalidMedia
        }
    }

    private static func collection(userID: String) -> CollectionReference {
        Firestore.firestore()
            .collection(usersCollection)
            .document(userID)
            .collection(momentsCollection)
    }

    private static func nonEmptyString(_ value: Any?) -> String? {
        guard let value = value as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func timestamp(_ value: Any?) -> Date? {
        if let timestamp = value as? Timestamp { return timestamp.dateValue() }
        return value as? Date
    }

    private static func userFacingMessage(for error: Error) -> String {
        let error = error as NSError
        if error.domain == FirestoreErrorDomain {
            switch error.code {
            case 7, 16:
                return "Your session no longer has access to this lore. Sign in again and retry."
            case 8:
                return "Solora is receiving too many requests. Please try again shortly."
            case 4, 14:
                return "Solora is offline. Your saved lore will sync when the connection returns."
            default:
                break
            }
        }
        return "Your lore could not be synced right now. Please try again."
    }
}

@MainActor
final class MomentStore: ObservableObject {
    @Published private(set) var moments: [SoloraMoment]
    @Published private(set) var isLoading: Bool
    @Published private(set) var isFromCache = false
    @Published private(set) var hasPendingWrites = false
    @Published var errorMessage: String?

    private enum Backend {
        case demo
        case firestore(userID: String)
    }

    private let backend: Backend
    private var listener: ListenerRegistration?

    init(userID: String, demoMoments: [SoloraMoment]) {
        if userID == AuthenticatedUser.demo.id {
            backend = .demo
            moments = demoMoments
            isLoading = false
        } else {
            backend = .firestore(userID: userID)
            moments = []
            isLoading = true
        }
    }

    deinit {
        listener?.remove()
    }

    func start() {
        guard listener == nil, case .firestore(let userID) = backend else { return }

        listener = FirebaseMomentRepository.observeMoments(userID: userID) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.apply(event)
            }
        }
    }

    @discardableResult
    func save(_ moment: SoloraMoment) -> Bool {
        errorMessage = nil

        switch backend {
        case .demo:
            insertOptimistically(moment)
            return true
        case .firestore(let userID):
            do {
                try FirebaseMomentRepository.saveMoment(moment, userID: userID) { [weak self] message in
                    guard let message else { return }
                    Task { @MainActor [weak self] in
                        self?.errorMessage = message
                    }
                }
                insertOptimistically(moment)
                hasPendingWrites = true
                return true
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription
                    ?? "This moment could not be saved. Please try again."
                return false
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    @discardableResult
    func delete(_ moment: SoloraMoment) -> Bool {
        errorMessage = nil

        switch backend {
        case .demo:
            removeOptimistically(moment.id)
            return true
        case .firestore(let userID):
            FirebaseMomentRepository.deleteMoment(id: moment.id, userID: userID) { [weak self] message in
                guard let message else { return }
                Task { @MainActor [weak self] in
                    self?.errorMessage = message
                }
            }
            removeOptimistically(moment.id)
            hasPendingWrites = true
            return true
        }
    }

    private func apply(_ event: MomentRepositoryEvent) {
        isLoading = false
        switch event {
        case .snapshot(let snapshot):
            moments = snapshot.moments
            isFromCache = snapshot.isFromCache
            hasPendingWrites = snapshot.hasPendingWrites
        case .failure(let message):
            errorMessage = message
        }
    }

    private func insertOptimistically(_ moment: SoloraMoment) {
        moments.removeAll { $0.id == moment.id }
        moments.append(moment)
        moments.sort { $0.date > $1.date }
    }

    private func removeOptimistically(_ identifier: String) {
        moments.removeAll { $0.id == identifier }
    }
}

private struct FirestoreMomentWrite: Encodable {
    let id: String
    let title: String
    let caption: String
    let occurredAt: Date
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    let world: String
    let schemaVersion: Int
    let category: String?
    let stickerPath: String?
    let photoPaths: [String]

    init(moment: SoloraMoment) {
        id = moment.id
        title = moment.title
        caption = moment.summary
        occurredAt = moment.date
        createdAt = nil
        updatedAt = nil
        world = moment.world.rawValue
        schemaVersion = 1
        category = moment.category
        stickerPath = moment.stickerPath
        photoPaths = moment.photoPaths
    }
}

private enum MomentRepositoryError: LocalizedError {
    case invalidIdentifier
    case invalidTitle
    case invalidSummary
    case invalidMedia

    var errorDescription: String? {
        switch self {
        case .invalidIdentifier:
            "This moment has an invalid identifier."
        case .invalidTitle:
            "Keep the moment title between 1 and 120 characters."
        case .invalidSummary:
            "Keep the reflection between 1 and 2,000 characters."
        case .invalidMedia:
            "This moment contains too many or invalid media references."
        }
    }
}
