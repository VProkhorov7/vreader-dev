import Foundation
import SwiftData
import Combine

final class ReadingSession: ObservableObject {
    static let shared = ReadingSession()

    @Published var lastBookID: UUID? = nil
    @Published var autoOpenBook: Book? = nil

    private let lastBookKey = "lastBookID"
    private let lastOpenedKey = "lastOpenedAt"

    private init() {
        lastBookID = loadLastBookID()
    }

    // MARK: - Сохранение

    func saveLastBook(_ book: Book, context: ModelContext) {
        lastBookID = book.id
        UserDefaults.standard.set(book.id.uuidString, forKey: lastBookKey)
        UserDefaults.standard.set(Date(), forKey: lastOpenedKey)
        book.lastOpenedAt = Date()
        try? context.save()
    }

    // MARK: - Загрузка

    func loadLastBookID() -> UUID? {
        UserDefaults.standard.string(forKey: lastBookKey)
            .flatMap { UUID(uuidString: $0) }
    }

    // MARK: - Поиск последней книги в SwiftData

    func findLastBook(in context: ModelContext) -> Book? {
        guard let id = lastBookID else { return nil }
        let predicate = #Predicate<Book> { $0.id == id }
        let descriptor = FetchDescriptor<Book>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastOpenedAt, order: .reverse)]
        )
        return try? context.fetch(descriptor).first
    }

    // MARK: - Очистка

    func clear() {
        lastBookID = nil
        autoOpenBook = nil
        UserDefaults.standard.removeObject(forKey: lastBookKey)
        UserDefaults.standard.removeObject(forKey: lastOpenedKey)
    }
}
