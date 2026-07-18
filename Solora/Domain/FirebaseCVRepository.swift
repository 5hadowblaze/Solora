@preconcurrency import FirebaseFirestore
import Foundation

enum FirebaseCVRepository {
    static let masterDocumentID = "master-extended-cv"

    static func fetch(userID: String) async throws -> (master: MasterCV, entries: [CVEntry]) {
        let user = Firestore.firestore().collection("users").document(userID)
        async let masterSnapshot = user.collection("cvDocuments").document(masterDocumentID).getDocument()
        async let entriesSnapshot = user.collection("cvEntries").getDocuments()

        guard let master = master(documentID: masterDocumentID, data: try await masterSnapshot.data()) else {
            throw CVRepositoryError.missingMaster
        }
        let entries = try await entriesSnapshot.documents
            .compactMap { entry(documentID: $0.documentID, data: $0.data()) }
            .sorted {
                if $0.type == $1.type { return $0.orderWithinType < $1.orderWithinType }
                return $0.type < $1.type
            }
        return (master, entries)
    }

    static func master(documentID: String, data: [String: Any]?) -> MasterCV? {
        guard let data,
              let title = data["title"] as? String,
              let contentMarkdown = data["contentMarkdown"] as? String,
              let profile = data["formatProfile"] as? [String: Any] else {
            return nil
        }

        return MasterCV(
            id: documentID,
            title: title,
            version: integer(data["version"]),
            contentMarkdown: contentMarkdown,
            structuredEntryCount: integer(data["structuredEntryCount"]),
            formatProfile: CVFormatProfile(
                languageVariant: profile["languageVariant"] as? String ?? "British English",
                voice: profile["voice"] as? String ?? "Achievement-focused",
                dateStyle: profile["dateStyle"] as? String ?? "Month YYYY – Month YYYY",
                sourceTypeface: profile["sourceTypeface"] as? String ?? "Garamond",
                sourcePageCount: integer(profile["sourcePageCount"])
            )
        )
    }

    static func entry(documentID: String, data: [String: Any]) -> CVEntry? {
        guard let type = data["type"] as? String,
              let title = data["title"] as? String else {
            return nil
        }

        return CVEntry(
            id: documentID,
            type: type,
            title: title,
            dateLabel: data["dateLabel"] as? String,
            descriptor: data["descriptor"] as? String,
            location: data["location"] as? String,
            bullets: data["bullets"] as? [String] ?? [],
            orderWithinType: integer(data["orderWithinType"])
        )
    }

    private static func integer(_ value: Any?) -> Int {
        if let value = value as? Int { return value }
        if let value = value as? Int64 { return Int(value) }
        if let value = value as? NSNumber { return value.intValue }
        return 0
    }
}

@MainActor
final class CVStore: ObservableObject {
    @Published private(set) var master: MasterCV?
    @Published private(set) var entries: [CVEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let userID: String

    init(userID: String) {
        self.userID = userID
    }

    func load() async {
        guard userID != AuthenticatedUser.demo.id, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await FirebaseCVRepository.fetch(userID: userID)
            master = snapshot.master
            entries = snapshot.entries
            errorMessage = nil
        } catch {
            errorMessage = "Your master CV could not be loaded right now."
        }
    }
}

private enum CVRepositoryError: Error {
    case missingMaster
}
