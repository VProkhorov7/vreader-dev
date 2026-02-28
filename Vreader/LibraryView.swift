import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.addedAt, order: .reverse) private var books: [Book]

    @State private var showImporter = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    ContentUnavailableView(
                        "Коллекция пуста",
                        systemImage: "books.vertical",
                        description: Text("Добавьте книги через облако или с устройства")
                    )
                } else {
                    List {
                        ForEach(books) { book in
                            NavigationLink {
                                ReaderView(book: book)
                            } label: {
                                BookRow(book: book)
                            }
                        }
                        .onDelete(perform: deleteBooks)
                    }
                }
            }
            .navigationTitle("Коллекция")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                #if DEBUG
                ToolbarItem(placement: .secondaryAction) {
                    Button("Добавить тестовые") {
                        insertSampleBooks()
                    }
                }
                #endif
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.pdf, .item],
                allowsMultipleSelection: true
            ) { result in
                handleImport(result: result)
            }
            .alert("Ошибка", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Actions

    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            let book = books[index]
            // Удаляем файл с диска
            if let url = book.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
            modelContext.delete(book)
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let book = try BookImporter.shared.importBook(from: url)
                    modelContext.insert(book)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    #if DEBUG
    private func insertSampleBooks() {
        Book.sampleBooks.forEach { modelContext.insert($0) }
    }
    #endif
}

// MARK: - BookRow

struct BookRow: View {
    let book: Book

    private var placeholderIcon: some View {
        Image(systemName: book.formatIcon)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.accentColor.gradient)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Обложка или заглушка
            Group {
                if let data = book.coverData {
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholderIcon
                    }
                    #elseif canImport(AppKit)
                    if let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholderIcon
                    }
                    #endif
                } else {
                    placeholderIcon
                }
            }
            .frame(width: 48, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if book.progress > 0 {
                    ProgressView(value: book.progress)
                        .tint(.accentColor)
                    Text("\(book.progressPercent)%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(book.format.uppercased())
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}
