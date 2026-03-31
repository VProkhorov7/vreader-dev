import Foundation
import Combine

enum CloudError: Error, LocalizedError {
    case notAuthenticated
    case fileNotFound(String)
    case uploadFailed(String)
    case downloadFailed(String)
    case quotaExceeded
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Authentication required." // TODO: replace with L10n.*
        case .fileNotFound(let f):
            return "File not found: \(f)" // TODO: replace with L10n.*
        case .uploadFailed(let m):
            return "Upload failed: \(m)" // TODO: replace with L10n.*
        case .downloadFailed(let m):
            return "Download failed: \(m)" // TODO: replace with L10n.*
        case .quotaExceeded:
            return "Storage quota exceeded." // TODO: replace with L10n.*
        case .networkUnavailable:
            return "No network connection." // TODO: replace with L10n.*
        }
    }
}

struct CloudFile: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let size: Int64
    let modifiedAt: Date
    let mimeType: String
    let isDirectory: Bool
}

protocol CloudProviderProtocol: AnyObject, ObservableObject {
    var id: String { get }
    var displayName: String { get }
    var icon: String { get }
    var isAuthenticated: Bool { get }
    var rootPath: String { get }

    func authenticate() async throws
    func signOut() async throws

    func listFiles(at path: String) async throws -> [CloudFile]
    func download(file: CloudFile, to localURL: URL, progress: @escaping (Double) -> Void) async throws
    func upload(from localURL: URL, to path: String, progress: @escaping (Double) -> Void) async throws -> CloudFile
    func delete(file: CloudFile) async throws

    func getStorageInfo() async throws -> (used: Int64, total: Int64)
}