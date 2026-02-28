// Book+Computed.swift
import Foundation
import SwiftUI

extension Book {
    /// Color for book cover display
    var color: Color {
        // Generate consistent color based on book title
        let hash = abs(title.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
    
    /// URL файла — безопасно, даже если filePath пустой
    var fileURL: URL? {
        guard !filePath.isEmpty else { return nil }
        return URL(fileURLWithPath: filePath)
    }

    /// Иконка SF Symbol по формату
    var formatIcon: String {
        switch format {
        case "pdf":  return "doc.fill"
        case "epub": return "book.fill"
        case "fb2":  return "text.book.closed.fill"
        default:     return "doc"
        }
    }

    /// Читабельный размер файла
    var formattedSize: String {
        guard fileSize > 0 else { return "" }
        return ByteCountFormatter.string(fromByteCount: fileSize,
                                         countStyle: .file)
    }

    /// Прогресс в процентах для UI
    var progressPercent: Int {
        Int(progress * 100)
    }
}
