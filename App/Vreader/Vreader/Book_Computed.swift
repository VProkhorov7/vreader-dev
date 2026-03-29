import Foundation
import SwiftUI

extension Book {

    var color: Color {
        let hash = abs(title.hashValue)
        let hue  = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }

    var fileURL: URL? {
        guard !filePath.isEmpty else { return nil }
        return URL(fileURLWithPath: filePath)
    }

    var isDownloaded: Bool {
        guard !filePath.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: filePath)
    }

    var formatIcon: String {
        switch format.lowercased() {
        case "pdf":  return "doc.fill"
        case "epub": return "book.fill"
        case "fb2":  return "text.book.closed.fill"
        case "djvu": return "doc.richtext.fill"
        case "mobi": return "book.pages.fill"
        case "cbz", "cbr": return "rectangle.stack.fill"
        default:     return "doc"
        }
    }

    var formatLabel: String {
        format.uppercased()
    }

    var sourceLabel: String {
        switch source.lowercased() {
        case "local":       return "Устройство"
        case "icloud":      return "iCloud"
        case "yandex":      return "Яндекс"
        case "googledrive": return "Google"
        case "dropbox":     return "Dropbox"
        case "onedrive":    return "OneDrive"
        case "amazons3":    return "Amazon"
        case "nextcloud":   return "Nextcloud"
        case "webdav":      return "WebDAV"
        case "smb":         return "SMB"
        case "opds":        return "OPDS"
        default:            return source.isEmpty ? "Устройство" : source
        }
    }

    var sourceColor: Color {
        switch source.lowercased() {
        case "local":       return Color(white: 0.4)
        case "icloud":      return Color(red: 0.0, green: 0.48, blue: 1.0)
        case "yandex":      return Color(red: 1.0, green: 0.2, blue: 0.2)
        case "googledrive": return Color(red: 0.26, green: 0.52, blue: 0.96)
        case "dropbox":     return Color(red: 0.0, green: 0.4, blue: 1.0)
        case "onedrive":    return Color(red: 0.0, green: 0.47, blue: 0.84)
        case "amazons3":    return Color(red: 1.0, green: 0.6, blue: 0.0)
        case "nextcloud":   return Color(red: 0.1, green: 0.5, blue: 0.9)
        case "webdav":      return Color(white: 0.5)
        case "smb":         return Color(red: 0.3, green: 0.3, blue: 0.5)
        default:            return Color(white: 0.4)
        }
    }

    var sourceIcon: String {
        switch source.lowercased() {
        case "local":       return "iphone"
        case "icloud":      return "icloud"
        case "yandex":      return "y.circle"
        case "googledrive": return "g.circle"
        case "dropbox":     return "archivebox"
        case "onedrive":    return "cloud"
        case "nextcloud":   return "cloud.circle"
        case "webdav":      return "server.rack"
        case "smb":         return "network"
        case "opds":        return "antenna.radiowaves.left.and.right"
        default:            return "externaldrive"
        }
    }

    var formatColor: Color {
        switch format.lowercased() {
        case "pdf":        return Color(red: 0.85, green: 0.15, blue: 0.1)
        case "epub":       return Color(red: 0.2, green: 0.6, blue: 0.3)
        case "fb2":        return Color(red: 0.5, green: 0.3, blue: 0.8)
        case "djvu":       return Color(red: 0.6, green: 0.4, blue: 0.1)
        case "mobi":       return Color(red: 0.0, green: 0.47, blue: 0.84)
        case "cbz", "cbr": return Color(red: 0.9, green: 0.5, blue: 0.0)
        default:           return Color(white: 0.4)
        }
    }

    var formattedSize: String {
        guard fileSize > 0 else { return "" }
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var progressPercent: Int {
        Int(progress * 100)
    }

    var remoteURL: URL? {
        guard !filePath.isEmpty, !isDownloaded else { return nil }
        return URL(string: filePath)
    }
}
