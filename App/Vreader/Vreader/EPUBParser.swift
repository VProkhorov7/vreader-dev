import Foundation
import ZIPFoundation

struct EPUBBook {
    let title:    String
    let author:   String
    let chapters: [EPUBChapter]
    let unpackDir: URL
}

struct EPUBChapter: Identifiable {
    let id:    Int
    let title: String
    let url:   URL
}

enum EPUBError: LocalizedError {
    case cannotUnpack
    case missingContainer
    case missingOPF
    case emptySpine

    var errorDescription: String? {
        switch self {
        case .cannotUnpack:     return "Не удалось распаковать EPUB"
        case .missingContainer: return "Отсутствует META-INF/container.xml"
        case .missingOPF:       return "Не найден файл OPF"
        case .emptySpine:       return "Список глав пуст (OPF spine)"
        }
    }
}

final class EPUBParser {

    static let shared = EPUBParser()
    private init() {}

    private var cache: [String: EPUBBook] = [:]

    func parse(url: URL) throws -> EPUBBook {
        if let cached = cache[url.path] { return cached }

        let unpackDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("epub_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: unpackDir, withIntermediateDirectories: true)

        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw EPUBError.cannotUnpack
        }

        for entry in archive {
            guard entry.type == .file else { continue }
            let dest = unpackDir.appendingPathComponent(entry.path)
            try FileManager.default.createDirectory(
                at: dest.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            _ = try archive.extract(entry, to: dest)
        }

        let containerURL = unpackDir
            .appendingPathComponent("META-INF")
            .appendingPathComponent("container.xml")
        guard FileManager.default.fileExists(atPath: containerURL.path) else {
            throw EPUBError.missingContainer
        }

        let opfRelPath = try parseContainer(at: containerURL)
        let opfURL = unpackDir.appendingPathComponent(opfRelPath)
        guard FileManager.default.fileExists(atPath: opfURL.path) else {
            throw EPUBError.missingOPF
        }

        let opfBase = opfURL.deletingLastPathComponent()
        let (title, author, chapters) = try parseOPF(at: opfURL, baseDir: opfBase)

        guard !chapters.isEmpty else { throw EPUBError.emptySpine }

        let book = EPUBBook(title: title, author: author, chapters: chapters, unpackDir: unpackDir)
        cache[url.path] = book
        return book
    }

    private func parseContainer(at url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let parser = ContainerXMLParser()
        return try parser.parse(data)
    }

    private func parseOPF(at url: URL, baseDir: URL) throws -> (String, String, [EPUBChapter]) {
        let data = try Data(contentsOf: url)
        let parser = OPFParser(baseDir: baseDir)
        return try parser.parse(data)
    }

    func clearCache() {
        for book in cache.values {
            try? FileManager.default.removeItem(at: book.unpackDir)
        }
        cache.removeAll()
    }
}

private final class ContainerXMLParser: NSObject, XMLParserDelegate {
    private var opfPath: String?

    func parse(_ data: Data) throws -> String {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.shouldProcessNamespaces = false
        xmlParser.parse()
        guard let path = opfPath else { throw EPUBError.missingOPF }
        return path
    }

    func parser(_ parser: XMLParser,
                didStartElement element: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes: [String: String]) {
        if element == "rootfile" || qName == "rootfile" {
            opfPath = attributes["full-path"]
        }
    }
}

private final class OPFParser: NSObject, XMLParserDelegate {
    private let baseDir: URL
    private var manifest: [String: String] = [:]
    private var spineIDs: [String] = []
    private var title  = "Без названия"
    private var author = "Неизвестный автор"
    private var currentText = ""
    private var inTitle   = false
    private var inCreator = false

    init(baseDir: URL) { self.baseDir = baseDir }

    func parse(_ data: Data) throws -> (String, String, [EPUBChapter]) {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.shouldProcessNamespaces = false
        xmlParser.parse()

        let chapters: [EPUBChapter] = spineIDs.enumerated().compactMap { idx, spineID in
            guard let href = manifest[spineID] else { return nil }
            let chapterURL = baseDir.appendingPathComponent(href)
            guard FileManager.default.fileExists(atPath: chapterURL.path) else { return nil }
            return EPUBChapter(id: idx, title: "Глава \(idx + 1)", url: chapterURL)
        }
        return (title, author, chapters)
    }

    func parser(_ parser: XMLParser,
                didStartElement element: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes: [String: String]) {
        currentText = ""
        let localName = qName ?? element
        switch localName {
        case "dc:title":   inTitle   = true
        case "dc:creator": inCreator = true
        case "item":
            if let id = attributes["id"], let href = attributes["href"] {
                manifest[id] = href
            }
        case "itemref":
            if let idref = attributes["idref"] { spineIDs.append(idref) }
        default: break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser,
                didEndElement element: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let localName = qName ?? element
        if inTitle   && !text.isEmpty { title  = text; inTitle   = false }
        if inCreator && !text.isEmpty { author = text; inCreator = false }
        if localName == "dc:title"   || localName == "title"   { inTitle   = false }
        if localName == "dc:creator" || localName == "creator" { inCreator = false }
        currentText = ""
    }
}
