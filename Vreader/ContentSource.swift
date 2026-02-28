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
    case error(ErrorCode)
}

protocol ContentSource {
    var id: ContentSourceID { get }
    var kind: ContentSourceKind { get }
    var displayName: String { get }
    var status: ContentSourceStatus { get }

    /// Check connection — called from setup wizard
    func testConnection(completion: @escaping (Result<Void, ErrorCode>) -> Void)

    /// List available books
    func listBooks(completion: @escaping (Result<[Book], ErrorCode>) -> Void)

    /// Create download task for a book
    func makeDownloadTask(for book: Book) -> DownloadTask?
}
