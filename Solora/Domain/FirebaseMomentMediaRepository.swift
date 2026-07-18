@preconcurrency import FirebaseStorage
import Foundation

enum FirebaseMomentMediaRepository {
    static let maximumUploadBytes = 8 * 1024 * 1024

    static func uploadPhoto(
        _ data: Data,
        userID: String,
        momentID: String,
        onProgress: @escaping @MainActor (Double) -> Void
    ) async throws -> String {
        guard !userID.isEmpty, !momentID.isEmpty else { throw MomentMediaError.missingOwner }
        guard !data.isEmpty, data.count <= maximumUploadBytes else { throw MomentMediaError.invalidSize }

        let fileName = "\(UUID().uuidString.lowercased()).jpg"
        let path = "users/\(userID)/wins/\(momentID)/photos/\(fileName)"
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "private,max-age=86400"

        do {
            _ = try await Storage.storage()
                .reference(withPath: path)
                .putDataAsync(data, metadata: metadata) { progress in
                    let fraction = progress?.fractionCompleted ?? 0
                    Task { @MainActor in onProgress(min(1, max(0, fraction))) }
                }
            await onProgress(1)
            return path
        } catch {
            throw MomentMediaError.uploadFailed(userFacingMessage(for: error))
        }
    }

    static func downloadURL(for path: String) async throws -> URL {
        guard !path.isEmpty else { throw MomentMediaError.invalidPath }
        if let url = URL(string: path), let scheme = url.scheme, scheme == "https" || scheme == "http" { return url }
        do {
            if path.hasPrefix("gs://") { return try await Storage.storage().reference(forURL: path).downloadURL() }
            return try await Storage.storage().reference(withPath: path).downloadURL()
        } catch { throw MomentMediaError.downloadFailed }
    }

    static func imageData(for path: String) async throws -> Data {
        guard !path.isEmpty else { throw MomentMediaError.invalidPath }
        do {
            if let url = URL(string: path), let scheme = url.scheme, scheme == "https" || scheme == "http" {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard data.count <= maximumUploadBytes, (response as? HTTPURLResponse)?.statusCode == 200 else { throw MomentMediaError.downloadFailed }
                return data
            }
            let reference = path.hasPrefix("gs://") ? Storage.storage().reference(forURL: path) : Storage.storage().reference(withPath: path)
            return try await reference.data(maxSize: Int64(maximumUploadBytes))
        } catch { throw MomentMediaError.downloadFailed }
    }

    private static func userFacingMessage(for error: Error) -> String {
        let error = error as NSError
        if error.domain == StorageErrorDomain {
            switch StorageErrorCode(rawValue: error.code) {
            case .unauthenticated, .unauthorized: return "Your session cannot upload this photo. Sign in again and retry."
            case .quotaExceeded: return "Photo storage is temporarily unavailable. Please try again later."
            case .retryLimitExceeded: return "The photo upload timed out. Check your connection and retry."
            default: break
            }
        }
        return "The photo could not be uploaded. Please try again."
    }
}

enum MomentMediaError: LocalizedError {
    case missingOwner, invalidSize, invalidPath, uploadFailed(String), downloadFailed
    var errorDescription: String? {
        switch self {
        case .missingOwner: "Sign in before adding a photo."
        case .invalidSize: "Choose a photo smaller than 8 MB."
        case .invalidPath: "This memory does not contain a valid photo reference."
        case .uploadFailed(let message): message
        case .downloadFailed: "This memory's photo is not available right now."
        }
    }
}
