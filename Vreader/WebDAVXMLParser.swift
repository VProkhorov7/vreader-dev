// Providers/WebDAVXMLParser.swift
import Foundation

final class WebDAVXMLParser: NSObject, XMLParserDelegate {

    private var files: [CloudFile] = []

    // Текущий разбираемый элемент
    private var currentHref     = ""
    private var currentName     = ""
    private var currentSize     : Int64 = 0
    private var currentModified = Date()
    private var currentIsDir    = false
    private var currentText     = ""
    private var insideResponse  = false

    // RFC 4918: все теги живут в неймспейсе "DAV:"
    private let davNS = "DAV:"

    func parse(_ data: Data) -> [CloudFile] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = true   // ← критично для WebDAV
        parser.parse()
        return files
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName: String?,
                attributes: [String: String]) {
        guard namespaceURI == davNS else { return }
        currentText = ""

        switch elementName {
        case "response":
            // Начало нового файла/папки
            insideResponse = true
            currentHref = ""
            currentName = ""
            currentSize = 0
            currentModified = Date()
            currentIsDir = false

        case "collection":
            // <resourcetype><collection/></resourcetype> → папка
            currentIsDir = true

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName: String?) {
        guard namespaceURI == davNS else { return }
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "href":
            currentHref = text
            // Имя файла — последний компонент пути
            currentName = URL(string: text)?.lastPathComponent
                            .removingPercentEncoding ?? text

        case "getcontentlength":
            currentSize = Int64(text) ?? 0

        case "getlastmodified":
            // RFC 1123: "Mon, 01 Jan 2024 12:00:00 GMT"
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            currentModified = fmt.date(from: text) ?? Date()

        case "displayname" where !text.isEmpty:
            currentName = text   // предпочитаем displayname если есть

        case "response" where insideResponse:
            // Пропускаем корневую директорию (первый response = сама папка)
            guard !currentName.isEmpty,
                  currentHref != "/" else { break }

            let mime: String
            if currentIsDir {
                mime = "inode/directory"
            } else {
                switch currentName.split(separator: ".").last?.lowercased() {
                case "pdf":  mime = "application/pdf"
                case "epub": mime = "application/epub+zip"
                case "fb2":  mime = "application/fb2"
                default:     mime = "application/octet-stream"
                }
            }

            files.append(CloudFile(
                id:          currentHref,
                name:        currentName,
                path:        currentHref,
                size:        currentSize,
                modifiedAt:  currentModified,
                mimeType:    mime,
                isDirectory: currentIsDir
            ))
            insideResponse = false

        default:
            break
        }

        currentText = ""
    }
}
