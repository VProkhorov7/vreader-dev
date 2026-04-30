import Foundation

enum DownloadState: String, Codable {
    case queued
    case running
    case paused
    case completed
    case failed
}

struct DownloadProgress {
    var bytesReceived: Int64
    var bytesExpected: Int64?

    var fraction: Double? {
        guard let expected = bytesExpected, expected > 0 else { return nil }
        return Double(bytesReceived) / Double(expected)
    }
}

protocol DownloadTask: AnyObject {
    var id: UUID { get }
    var bookID: UUID { get }
    var sourceID: ContentSourceID { get }

    var state: DownloadState { get }
    var progress: DownloadProgress { get }
    var error: AppError? { get }

    func start()
    func pause()
    func cancel()
}