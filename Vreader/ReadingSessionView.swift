import SwiftUI
import SwiftData

struct ReadingSessionView: View {
    @Query(sort: \Book.lastOpenedAt, order: .reverse) private var books: [Book]
    @State private var selectedBook: Book?

    var body: some View {
        Group {
            if let book = selectedBook {
                // Полноэкранный ридер — это и есть главная reading pane
                ReaderView(book: book)
                    .ignoresSafeArea()
                    .navigationBarHidden(true)
                    .navigationBarTitleDisplayMode(.inline)
            } else if !books.isEmpty {
                // Нет последней книги — выбор из недавно открытых
                RecentlyReadList(books: books) { book in
                    selectedBook = book
                }
            } else {
                EmptyLibraryView()
            }
        }
        .onAppear {
            loadLastSession()
        }
        .navigationTitle("Читаю")
    }

    private func loadLastSession() {
        // ReadingSession.shared.loadLastBook() → selectedBook
        selectedBook = books.first  // пока заглушка
    }
}
