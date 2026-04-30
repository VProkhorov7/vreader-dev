import Foundation
import SwiftUI
import Observation

enum BookFormat: String, CaseIterable {
    case pdf   = "pdf"
    case epub  = "epub"
    case fb2   = "fb2"
    case txt   = "txt"
    case rtf   = "rtf"
    case cbz   = "cbz"
    case cbr   = "cbr"
    case cb7   = "cb7"
    case cbt   = "cbt"
    case mobi  = "mobi"
    case azw3  = "azw3"
    case djvu  = "djvu"
    case chm   = "chm"
    case mp3   = "mp3"
    case m4a   = "m4a"
    case m4b   = "m4b"

    init?(url: URL) {
        let name = url.lastPathComponent.lowercased()
        if name.hasSuffix(".fb2.zip") {
            self = .fb2; return
        }
        self.init(rawValue: url.pathExtension.lowercased())
    }

    var isAudio: Bool { self == .mp3 || self == .m4a || self == .m4b }
    var isComic: Bool { self == .cbz || self == .cbr || self == .cb7 || self == .cbt }
}

@Observable
@MainActor
final class BookImporter {
    static let shared = BookImporter()

    private let booksDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir  = docs.appendingPathComponent("Books", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func importBook(from sourceURL: URL, source: String = "local") throws -> Book {
        guard let format = BookFormat(url: sourceURL) else {
            throw AppError(
                code: .parsing(.unsupportedFormat),
                description: "The file format '\(sourceURL.pathExtension)' is not supported.",
                recoveryHint: "Supported formats: EPUB, FB2, PDF, DjVu, CBZ, CBR, TXT, RTF, MP3, M4B."
            )
        }

        let ext     = format.rawValue
        let destURL = booksDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)")

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            throw AppError(
                code: .fileSystem(.permissionDenied),
                description: "Failed to copy the file to the library.",
                recoveryHint: "Check available storage space and file permissions.",
                underlyingError: error as? (any Error & Sendable)
            )
        }

        let attrs    = try? FileManager.default.attributesOfItem(atPath: destURL.path)
        let fileSize = attrs?[.size] as? Int64 ?? 0

        let title = sourceURL
            .deletingPathExtension()
            .lastPathComponent
            .removingPercentEncoding ?? sourceURL.lastPathComponent

        return Book(
            title:    title,
            filePath: destURL.path,
            format:   ext,
            source:   source,
            fileSize: fileSize
        )
    }
}