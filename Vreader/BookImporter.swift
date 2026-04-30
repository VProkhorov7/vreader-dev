import Foundation
import SwiftUI
import Observation

enum BookFormat: String {
    case pdf  = "pdf"
    case epub = "epub"
    case fb2  = "fb2"

    init?(url: URL) {
        self.init(rawValue: url.pathExtension.lowercased())
    }
}

@Observable
@MainActor
final class BookImporter {
    static let shared = BookImporter()

    private let booksDirectory: URL = {
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Books", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
        return dir
    }()

    func importBook(from sourceURL: URL,
                    source: String = "local") throws -> Book {

        guard let format = BookFormat(url: sourceURL) else {
            throw AppError(
                code: .parsing(.unsupportedFormat),
                description: "The file format '\(sourceURL.pathExtension)' is not supported.",
                recoveryHint: "Supported formats: EPUB, FB2, PDF."
            )
        }

        let uniqueName = "\(UUID().uuidString).\(format.rawValue)"
        let destURL    = booksDirectory.appendingPathComponent(uniqueName)

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
            format:   format.rawValue,
            source:   source,
            fileSize: fileSize
        )
    }
}