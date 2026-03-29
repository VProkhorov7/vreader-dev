import Foundation
import SwiftData

@Model
final class Book: Identifiable {
    var id:           UUID   = UUID()
    var title:        String = ""
    var author:       String = "Неизвестный автор"
    var coverData:    Data?  = nil
    var filePath:     String = ""
    var format:       String = "pdf"
    var fileSize:     Int64  = 0
    var source:       String = "local"
    var addedAt:      Date   = Date()
    var progress:     Double = 0.0
    var lastPage:     Int    = 0
    var lastOpenedAt: Date?  = nil
    var isFinished:   Bool   = false

    init(title:    String,
         author:   String = "Неизвестный автор",
         filePath: String = "",
         format:   String = "pdf",
         source:   String = "local",
         fileSize: Int64  = 0) {
        self.title    = title
        self.author   = author
        self.filePath = filePath
        self.format   = format
        self.source   = source
        self.fileSize = fileSize
        self.addedAt  = Date()
    }
}

