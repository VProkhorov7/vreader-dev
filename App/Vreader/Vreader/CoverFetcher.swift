// CoverFetcher.swift
import Foundation
import SwiftData

// MARK: - Загрузчик обложек
//
// Источники (по приоритету):
// 1. Open Library Covers API — бесплатно, 20M+ книг, поиск по title+author
// 2. Google Books API        — бесплатно без ключа (100 req/day)

@MainActor
final class CoverFetcher {
    static let shared = CoverFetcher()
    private init() {}

    private var inProgress: Set<UUID> = []

    // MARK: - Загрузить обложку для одной книги

    func fetchIfNeeded(book: Book, context: ModelContext) {
        guard book.coverData == nil,
              !book.title.isEmpty,
              !inProgress.contains(book.id) else { return }

        inProgress.insert(book.id)

        Task {
            defer { inProgress.remove(book.id) }

            if let data = await fetchFromOpenLibrary(title: book.title, author: book.author) {
                book.coverData = data
                try? context.save()
            } else if let data = await fetchFromGoogleBooks(title: book.title, author: book.author) {
                book.coverData = data
                try? context.save()
            }
        }
    }

    // MARK: - Загрузить обложки для всей библиотеки

    func fetchAllMissing(books: [Book], context: ModelContext) {
        let missing = books.filter { $0.coverData == nil && !$0.title.isEmpty }
        // Грузим с паузой чтобы не перегружать API
        Task {
            for (index, book) in missing.enumerated() {
                if index > 0 {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3с между запросами
                }
                fetchIfNeeded(book: book, context: context)
            }
        }
    }

    // MARK: - Open Library

    private func fetchFromOpenLibrary(title: String, author: String) async -> Data? {
        // Шаг 1: поиск ID книги
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        let query = "\(title) \(author)".trimmingCharacters(in: .whitespaces)
        components.queryItems = [
            URLQueryItem(name: "q",      value: query),
            URLQueryItem(name: "fields", value: "cover_i,title"),
            URLQueryItem(name: "limit",  value: "1")
        ]
        guard let url = components.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let docs  = json?["docs"] as? [[String: Any]]
            guard let coverID = docs?.first?["cover_i"] as? Int else { return nil }

            // Шаг 2: загружаем обложку по ID
            let coverURL = URL(string: "https://covers.openlibrary.org/b/id/\(coverID)-M.jpg")!
            let (imgData, response) = try await URLSession.shared.data(from: coverURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  imgData.count > 1000 else { return nil }  // отсекаем пустые заглушки
            return imgData
        } catch {
            return nil
        }
    }

    // MARK: - Google Books (резерв)

    private func fetchFromGoogleBooks(title: String, author: String) async -> Data? {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        components.queryItems = [
            URLQueryItem(name: "q",          value: "intitle:\(title)+inauthor:\(author)"),
            URLQueryItem(name: "maxResults", value: "1"),
            URLQueryItem(name: "fields",     value: "items/volumeInfo/imageLinks")
        ]
        guard let url = components.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let items = json?["items"] as? [[String: Any]]
            let imageLinks = items?.first?["volumeInfo"] as? [String: Any]
            let links      = imageLinks?["imageLinks"] as? [String: String]

            // Предпочитаем thumbnail, он квадратный и быстрый
            guard var imgURLStr = links?["thumbnail"] ?? links?["smallThumbnail"] else { return nil }
            // Переключаем на HTTPS и убираем zoom для качества
            imgURLStr = imgURLStr.replacingOccurrences(of: "http://", with: "https://")
            imgURLStr = imgURLStr.replacingOccurrences(of: "&zoom=1", with: "")

            guard let imgURL = URL(string: imgURLStr) else { return nil }
            let (imgData, response) = try await URLSession.shared.data(from: imgURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  imgData.count > 1000 else { return nil }
            return imgData
        } catch {
            return nil
        }
    }
}
