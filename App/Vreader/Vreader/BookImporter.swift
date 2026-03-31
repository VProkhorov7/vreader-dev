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

enum ImportError: Error, LocalizedError {
    case unsupportedFormat(String)
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let e): return "Unsupported format: \(e)"
        case .copyFailed(let e):        return "Copy failed: \(e)"
        }
    }
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
            throw ImportError.unsupportedFormat(sourceURL.pathExtension)
        }
        let dest = booksDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: sourceURL, to: dest)
        } catch {
            throw ImportError.copyFailed(error.localizedDescription)
        }
        let attrs  = try? FileManager.default.attributesOfItem(atPath: dest.path)
        let size   = (attrs?[.size] as? Int64) ?? 0
        let title  = sourceURL.deletingPathExtension().lastPathComponent
        return Book(
            title:    title,
            filePath: dest.path,
            format:   format.rawValue,
            source:   source,
            fileSize: size
        )
    }
}
