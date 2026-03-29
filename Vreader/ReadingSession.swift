// ReadingSession.swift — ПОЛНАЯ РАБОЧАЯ ВЕРСИЯ
import Foundation
import SwiftData
import Combine

final class ReadingSession: ObservableObject {
    static let shared = ReadingSession()

    private let lastBookKey = "ReadingSessionLastBookID"
    private let lastOpenedKey = "ReadingSessionLastOpened"
    
    @Published var lastBookID: UUID?
    
    private init() {
        lastBookID = loadLastBookID()
    }

    // MARK: - Сохранение

    func saveLastBook(_ book: Book, context: ModelContext) {
        lastBookID = book.id
        UserDefaults.standard.set(book.id.uuidString, forKey: lastBookKey)
        UserDefaults.standard.set(Date(), forKey: lastOpenedKey)
        
        // Обновляем метаданные книги
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
        let fetchDescriptor = FetchDescriptor<Book>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastOpenedAt, order: .reverse)]
        )
        
        return try? context.fetch(fetchDescriptor).first
    }

    // MARK: - Очистка сессии

    func clear() {
        lastBookID = nil
        UserDefaults.standard.removeObject(forKey: lastBookKey)
        UserDefaults.standard.removeObject(forKey: lastOpenedKey)
    }
}
