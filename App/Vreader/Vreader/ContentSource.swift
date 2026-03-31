import Foundation

struct ContentSourceID: Hashable, Codable {
    let rawValue: String
}

enum ContentSourceKind: String, Codable {
    case localFiles
    case googleDrive
    case dropbox
    case oneDrive
    case yandexDisk
    case webDAV
    case smb
    case opds
}

enum ContentSourceStatus {
    case disconnected
    case connecting
    case connected
    case error(AppError)
}

protocol ContentSource {
    var id: ContentSourceID { get }
    var kind: ContentSourceKind { get }
    var displayName: String { get }
    var status: ContentSourceStatus { get }

    func testConnection(completion: @escaping (Result<Void, AppError>) -> Void)
    func listBooks(completion: @escaping (Result<[Book], AppError>) -> Void)
    func makeDownloadTask(for book: Book) -> DownloadTask?
}
