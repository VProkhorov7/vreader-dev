import Foundation
import Combine

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