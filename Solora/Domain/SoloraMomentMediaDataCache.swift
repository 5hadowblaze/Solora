import CryptoKit
import Foundation

/// Keeps personal memory media available across Solora's surfaces without repeatedly
/// requesting the same image from Firebase Storage.
actor SoloraMomentMediaDataCache {
    static let shared = SoloraMomentMediaDataCache()

    private let memoryLimit = 32 * 1_024 * 1_024
    private let diskLimit = 160 * 1_024 * 1_024
    private var cachedData: [String: Data] = [:]
    private var cacheOrder: [String] = []
    private var cachedByteCount = 0
    private var inFlight: [String: Task<Data?, Never>] = [:]

    func data(for path: String) async throws -> Data {
        guard !path.isEmpty else { throw MomentMediaError.invalidPath }

        if let cached = cachedData[path] {
            touch(path)
            return cached
        }

        if let diskData = try? Data(contentsOf: diskURL(for: path)), !diskData.isEmpty {
            remember(diskData, for: path)
            return diskData
        }

        if let task = inFlight[path] {
            guard let data = await task.value else { throw MomentMediaError.downloadFailed }
            return data
        }

        let task = Task<Data?, Never> {
            try? await FirebaseMomentMediaRepository.imageData(for: path)
        }
        inFlight[path] = task
        let downloaded = await task.value
        inFlight[path] = nil

        guard let downloaded else { throw MomentMediaError.downloadFailed }
        remember(downloaded, for: path)
        persist(downloaded, for: path)
        return downloaded
    }

    /// Starts downloading known memory media as soon as the user's lore is loaded.
    /// The work is deliberately sequential: it avoids competing with the rest of the
    /// app for the user's connection while still leaving every visited page warm.
    func preload(paths: [String]) async {
        let uniquePaths = Array(Set(paths.filter { !$0.isEmpty }))
        for path in uniquePaths {
            _ = try? await data(for: path)
        }
    }

    func remove(paths: [String]) {
        for path in paths where !path.isEmpty {
            if let data = cachedData.removeValue(forKey: path) {
                cachedByteCount -= data.count
            }
            cacheOrder.removeAll { $0 == path }
            try? FileManager.default.removeItem(at: diskURL(for: path))
        }
    }

    private var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SoloraMomentMedia", isDirectory: true)
    }

    private func diskURL(for path: String) -> URL {
        let digest = SHA256.hash(data: Data(path.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return cacheDirectory.appendingPathComponent(digest).appendingPathExtension("media")
    }

    private func remember(_ data: Data, for path: String) {
        if let existing = cachedData[path] {
            cachedByteCount -= existing.count
        }
        cachedData[path] = data
        cachedByteCount += data.count
        touch(path)

        while cachedByteCount > memoryLimit, let oldest = cacheOrder.first {
            cacheOrder.removeFirst()
            if let removed = cachedData.removeValue(forKey: oldest) {
                cachedByteCount -= removed.count
            }
        }
    }

    private func touch(_ path: String) {
        cacheOrder.removeAll { $0 == path }
        cacheOrder.append(path)
    }

    private func persist(_ data: Data, for path: String) {
        let directory = cacheDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: diskURL(for: path), options: .atomic)
        trimDiskCacheIfNeeded()
    }

    private func trimDiskCacheIfNeeded() {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else { return }

        let entries = files.compactMap { url -> (URL, Int, Date)? in
            guard let values = try? url.resourceValues(forKeys: keys),
                  let size = values.fileSize else { return nil }
            return (url, size, values.contentModificationDate ?? .distantPast)
        }
        var total = entries.reduce(0) { $0 + $1.1 }
        guard total > diskLimit else { return }

        for (url, size, _) in entries.sorted(by: { $0.2 < $1.2 }) where total > diskLimit {
            try? FileManager.default.removeItem(at: url)
            total -= size
        }
    }
}
