// CloudProviderProtocol.swift
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
        case .notAuthenticated:      return "Требуется авторизация"
        case .fileNotFound(let f):   return "Файл не найден: \(f)"
        case .uploadFailed(let m):   return "Ошибка загрузки: \(m)"
        case .downloadFailed(let m): return "Ошибка скачивания: \(m)"
        case .quotaExceeded:         return "Недостаточно места"
        case .networkUnavailable:    return "Нет сети"
        }
    }
}

struct CloudFile: Identifiable, Hashable {
    let id: String          // уникальный ID у провайдера
    let name: String
    let path: String
    let size: Int64
    let modifiedAt: Date
    let mimeType: String    // "application/pdf" / "application/epub+zip"
    let isDirectory: Bool
}

protocol CloudProviderProtocol: AnyObject, ObservableObject {
    var id: String { get }              // "icloud" | "gdrive" | "dropbox" | "webdav"
    var displayName: String { get }
    var icon: String { get }            // SF Symbol или asset name
    var isAuthenticated: Bool { get }
    var rootPath: String { get }

    // Auth
    func authenticate() async throws
    func signOut() async throws

    // File operations
    func listFiles(at path: String) async throws -> [CloudFile]
    func download(file: CloudFile, to localURL: URL, progress: @escaping (Double) -> Void) async throws
    func upload(from localURL: URL, to path: String, progress: @escaping (Double) -> Void) async throws -> CloudFile
    func delete(file: CloudFile) async throws

    // Meta
    func getStorageInfo() async throws -> (used: Int64, total: Int64)
}
