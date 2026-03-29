import SwiftUI
import SwiftData

struct ReadingView: View {
    @StateObject private var session = ReadingSession.shared
    @State private var autoOpenBook: Book? = nil
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 200
    private var readingBooks: [Book] {
        Book.sampleBooks.filter { $0.progress > 0 && $0.progress < 1 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let book = readingBooks.first {
                    CurrentlyReadingCard(book: book)
                        .padding(.horizontal, 20)
                }
                if readingBooks.dropFirst().count > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("В процессе")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        ForEach(Array(readingBooks.dropFirst())) { book in
                            NavigationLink {
                                ReaderView(book: book)
                                    .onAppear {
                                        ReadingSession.shared.lastBookID = book.id
                                    }
                            } label: {
                                ReadingRow(book: book)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(Text("tab.reading"))
        .onAppear {
            if let id = session.lastBookID,
               let book = Book.sampleBooks.first(where: { $0.id == id }) {
                autoOpenBook = book
            }
        }
        .navigationDestination(item: $autoOpenBook) { book in
            ReaderView(book: book)
        }
    }
}

// MARK: - Большая карточка текущей книги

struct CurrentlyReadingCard: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(book.color.gradient)
                    .frame(width: 80, height: 120)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Продолжить чтение")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(book.title)
                        .font(.title3.bold())
                        .lineLimit(2)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(book.progress * 100))% прочитано")
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: book.progress)
                    .tint(Color.accentColor)
                HStack {
                    Text("Начало")
                        .font(.caption).foregroundStyle(.tertiary)
                    Spacer()
                    Text("Конец")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }

            NavigationLink {
                ReaderView(book: book)
                    .onAppear {
                        ReadingSession.shared.lastBookID = book.id
                    }
            } label: {
                Text("Читать")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Строка книги в процессе

struct ReadingRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(book.color.gradient)
                .frame(width: 44, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                ProgressView(value: book.progress)
                    .tint(Color.accentColor)
                Text("\(Int(book.progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ReadingView()
    }
}
