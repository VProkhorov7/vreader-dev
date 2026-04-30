import Foundation
import Combine

final class ICloudProvider: CloudProviderProtocol {
    let id = "icloud"
    let displayName = "iCloud Drive"
    let icon = "icloud"
    let rootPath = "/"

    @Published var isAuthenticated: Bool = false

    private let containerID = "iCloud.com.yourapp.VReader"
    private var containerURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: containerID)
            .map { $0.appendingPathComponent("Documents") }
    }

    func authenticate() async throws {
        guard containerURL != nil else {
            throw AppError(
                code: .auth(.credentialsMissing),
                description: "iCloud container is unavailable.",
                recoveryHint: "Sign in to iCloud in System Settings and try again."
            )
        }
        isAuthenticated = true
    }

    func signOut() async throws {
        isAuthenticated = false
    }

    func listFiles(at path: String) async throws -> [CloudFile] {
        guard let base = containerURL else {
            throw AppError(
                code: .auth(.credentialsMissing),
                description: "iCloud container is unavailable.",
                recoveryHint: "Sign in to iCloud in System Settings and try again."
            )
        }
        let dir = base.appendingPathComponent(path)

        return try await withCheckedThrowingContinuation { continuation in
            let query = NSMetadataQuery()
            query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            query.predicate = NSPredicate(
                format: "%K BEGINSWITH %@",
                NSMetadataItemPathKey,
                dir.path
            )
            continuation.resume(returning: [])
        }
    }

    func download(file: CloudFile,
                  to localURL: URL,
                  progress: @escaping (Double) -> Void) async throws {

        guard let base = containerURL else {
            throw AppError(
                code: .auth(.credentialsMissing),
                description: "iCloud container is unavailable.",
                recoveryHint: "Sign in to iCloud in System Settings and try again."
            )
        }

        let sourceURL = base.appendingPathComponent(file.path)

        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: sourceURL)
        } catch {
        }

        try await waitForUbiquitousDownload(at: sourceURL, progress: progress)

        try? FileManager.default.removeItem(at: localURL)
        try FileManager.default.copyItem(at: sourceURL, to: localURL)

        await MainActor.run { progress(1.0) }
    }

    func upload(from localURL: URL,
                to path: String,
                progress: @escaping (Double) -> Void) async throws -> CloudFile {

        guard let base = containerURL else {
            throw AppError(
                code: .auth(.credentialsMissing),
                description: "iCloud container is unavailable.",
                recoveryHint: "Sign in to iCloud in System Settings and try again."
            )
        }

        let destinationURL = base
            .appendingPathComponent(path)
            .appendingPathComponent(localURL.lastPathComponent)

        let parentDir = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.copyItem(at: localURL, to: destinationURL)

        await MainActor.run { progress(1.0) }

        let attrs = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let size = attrs[.size] as? Int64 ?? 0
        let modifiedDate = attrs[.modificationDate] as? Date ?? Date()

        return CloudFile(
            id: destinationURL.path,
            name: localURL.lastPathComponent,
            path: path + "/" + localURL.lastPathComponent,
            size: size,
            modifiedAt: modifiedDate,
            mimeType: mimeType(for: localURL.pathExtension),
            isDirectory: false
        )
    }

    func delete(file: CloudFile) async throws {
        guard let base = containerURL else {
            throw AppError(
                code: .auth(.credentialsMissing),
                description: "iCloud container is unavailable.",
                recoveryHint: "Sign in to iCloud in System Settings and try again."
            )
        }

        let fileURL = base.appendingPathComponent(file.path)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw AppError(
                code: .fileSystem(.fileNotFound),
                description: "The file '\(file.name)' was not found in iCloud.",
                recoveryHint: "The file may have been deleted from iCloud. Refresh your library."
            )
        }

        try FileManager.default.removeItem(at: fileURL)
    }

    func getStorageInfo() async throws -> (used: Int64, total: Int64) {
        guard let base = containerURL else {
            throw AppError(
                code: .auth(.credentialsMissing),
                description: "iCloud container is unavailable.",
                recoveryHint: "Sign in to iCloud in System Settings and try again."
            )
        }

        let used = try calculateDirectorySize(at: base)
        let total: Int64 = 0

        return (used: used, total: total)
    }

    private func calculateDirectorySize(at url: URL) throws -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attrs?.fileSize ?? 0)
            }
        }

        return totalSize
    }

    private func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "pdf":
            return "application/pdf"
        case "epub":
            return "application/epub+zip"
        case "txt":
            return "text/plain"
        case "mobi":
            return "application/x-mobipocket-ebook"
        default:
            return "application/octet-stream"
        }
    }

    private func waitForUbiquitousDownload(at url: URL,
                                           progress: @escaping (Double) -> Void) async throws {
        let keys: Set<URLResourceKey> = [.ubiquitousItemDownloadingStatusKey]

        for attempt in 0..<120 {
            let attrs = try? url.resourceValues(forKeys: keys)

            switch attrs?.ubiquitousItemDownloadingStatus {
            case .current:
                return
            case .downloaded:
                return
            default:
                let estimatedProgress = min(0.9, Double(attempt) / 100.0)
                await MainActor.run { progress(estimatedProgress) }
            }

            if attempt > 5 {
                let exists = (try? url.checkResourceIsReachable()) ?? false
                if !exists {
                    throw AppError(
                        code: .fileSystem(.fileNotFound),
                        description: "The iCloud file does not exist at the expected location.",
                        recoveryHint: "Check your iCloud connection and try again."
                    )
                }
            }

            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        throw AppError(
            code: .network(.timeout),
            description: "iCloud download timed out.",
            recoveryHint: "Check your internet connection and try again."
        )
    }
}