@preconcurrency import FirebaseStorage
import CoreImage
import Foundation
import UIKit
import Vision

enum FirebaseMomentMediaRepository {
    static let maximumUploadBytes = 8 * 1024 * 1024
    static let maximumMotionUploadBytes = 16 * 1024 * 1024

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

    static func uploadSticker(
        _ data: Data,
        userID: String,
        momentID: String
    ) async throws -> String {
        guard !userID.isEmpty, !momentID.isEmpty else { throw MomentMediaError.missingOwner }
        guard !data.isEmpty, data.count <= maximumUploadBytes else { throw MomentMediaError.invalidSize }

        let fileName = "\(UUID().uuidString.lowercased()).png"
        let path = "users/\(userID)/wins/\(momentID)/stickers/\(fileName)"
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        metadata.cacheControl = "private,max-age=86400"

        do {
            _ = try await Storage.storage().reference(withPath: path).putDataAsync(data, metadata: metadata)
            return path
        } catch {
            throw MomentMediaError.uploadFailed(userFacingMessage(for: error))
        }
    }

    static func uploadLivePhotoMotion(
        _ data: Data,
        userID: String,
        momentID: String,
        onProgress: @escaping @MainActor (Double) -> Void
    ) async throws -> String {
        guard !userID.isEmpty, !momentID.isEmpty else { throw MomentMediaError.missingOwner }
        guard !data.isEmpty, data.count <= maximumMotionUploadBytes else { throw MomentMediaError.invalidMotionSize }

        let fileName = "\(UUID().uuidString.lowercased()).mov"
        let path = "users/\(userID)/wins/\(momentID)/motion/\(fileName)"
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        metadata.cacheControl = "private,max-age=86400"
        do {
            _ = try await Storage.storage().reference(withPath: path).putDataAsync(data, metadata: metadata) { progress in
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

enum SoloraStickerComposer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func stickerPNG(from photoData: Data) -> Data? {
        guard let image = UIImage(data: photoData),
              let source = foregroundCutout(from: image) ?? normalized(image) else {
            return nil
        }
        return outlined(source).pngData()
    }

    private static func foregroundCutout(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation),
            options: [:]
        )
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
            guard let result = request.results?.first, !result.allInstances.isEmpty else { return nil }
            let mask = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
            let image = CIImage(cvPixelBuffer: mask)
            guard let output = context.createCGImage(image, from: image.extent) else { return nil }
            return UIImage(cgImage: output, scale: 1, orientation: .up)
        } catch {
            return nil
        }
    }

    private static func normalized(_ image: UIImage) -> UIImage? {
        guard image.cgImage != nil else { return nil }
        if image.imageOrientation == .up { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private static func outlined(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let base = CIImage(cgImage: cgImage)
        let border = max(5, min(base.extent.width, base.extent.height) * 0.025)
        let padding = ceil(border) + 2
        let extent = base.extent.insetBy(dx: -padding, dy: -padding)
        let clear = CIImage(color: .clear).cropped(to: extent)
        let padded = base.composited(over: clear)
        let white = CIImage(color: .white).cropped(to: extent)

        guard let blend = CIFilter(name: "CIBlendWithAlphaMask") else { return image }
        blend.setValue(white, forKey: kCIInputImageKey)
        blend.setValue(clear, forKey: kCIInputBackgroundImageKey)
        blend.setValue(padded, forKey: kCIInputMaskImageKey)
        guard var outline = blend.outputImage else { return image }
        if let dilate = CIFilter(name: "CIMorphologyMaximum") {
            dilate.setValue(outline, forKey: kCIInputImageKey)
            dilate.setValue(border, forKey: "inputRadius")
            outline = dilate.outputImage ?? outline
        }
        guard let output = context.createCGImage(padded.composited(over: outline), from: extent) else { return image }
        return UIImage(cgImage: output, scale: image.scale, orientation: .up)
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

enum MomentMediaError: LocalizedError {
    case missingOwner, invalidSize, invalidMotionSize, invalidPath, uploadFailed(String), downloadFailed
    var errorDescription: String? {
        switch self {
        case .missingOwner: "Sign in before adding a photo."
        case .invalidSize: "Choose a photo smaller than 8 MB."
        case .invalidMotionSize: "Choose a Live Photo with a motion clip smaller than 16 MB."
        case .invalidPath: "This memory does not contain a valid photo reference."
        case .uploadFailed(let message): message
        case .downloadFailed: "This memory's photo is not available right now."
        }
    }
}
