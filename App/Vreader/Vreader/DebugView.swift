#if DEBUG
import SwiftUI
import SwiftData

struct DebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @State private var path = NavigationPath()
    @Environment(ThemeStore.self) private var themeStore

    var body: some View {
        NavigationStack(path: $path) {
            List {
                screensSection
                componentsSection
                actionsSection
                stateSection
            }
            .navigationTitle("🔨 Debug")
            .navigationDestination(for: DebugDestination.self) { dest in
                destinationView(for: dest)
            }
        }
    }

    private var screensSection: some View {
        Section("Экраны") {
            DebugNavRow(icon: "books.vertical.fill", label: "LibraryView", color: .blue) {
                path.append(DebugDestination.library)
            }
            DebugNavRow(icon: "book.fill", label: "ReaderView (sample[0])", color: .orange) {
                path.append(DebugDestination.reader)
            }
            DebugNavRow(icon: "globe", label: "OnlineView", color: .green) {
                path.append(DebugDestination.online)
            }
            DebugNavRow(icon: "gearshape.fill", label: "SettingsView", color: .gray) {
                path.append(DebugDestination.settings)
            }
            DebugNavRow(icon: "cloud.fill", label: "CloudStorageView", color: .cyan) {
                path.append(DebugDestination.cloud)
            }
            DebugNavRow(icon: "book.closed.fill", label: "ReadingView", color: .purple) {
                path.append(DebugDestination.reading)
            }
        }
    }

    private var componentsSection: some View {
        Section("Компоненты") {
            DebugNavRow(icon: "rectangle.grid.2x2.fill", label: "BookCardView (сетка)", color: .indigo) {
                path.append(DebugDestination.bookCards)
            }
            DebugNavRow(icon: "list.bullet", label: "BookRow (список)", color: .teal) {
                path.append(DebugDestination.bookRows)
            }
            DebugNavRow(icon: "globe", label: "CatalogRow", color: .mint) {
                path.append(DebugDestination.catalogRows)
            }
        }
    }

    private var actionsSection: some View {
        Section("Действия") {
            Button {
                Book.samples.forEach { modelContext.insert($0) }
            } label: {
                Label("Вставить 3 тестовые книги", systemImage: "plus.circle.fill")
            }
            Button {
                books.forEach { book in
                    book.progress = Double.random(in: 0.05...0.95)
                }
                try? modelContext.save()
            } label: {
                Label("Рандомизировать прогресс", systemImage: "shuffle")
            }
            Button {
                books.forEach { book in
                    book.progress = 0
                    book.lastPage = 0
                }
                try? modelContext.save()
            } label: {
                Label("Сбросить прогресс", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(.orange)
            }
            Button(role: .destructive) {
                books.forEach { modelContext.delete($0) }
                try? modelContext.save()
            } label: {
                Label("Удалить все книги", systemImage: "trash.fill")
            }
        }
    }

    private var stateSection: some View {
        Section("AppState") {
            LabeledContent("selectedTab", value: AppState.shared.selectedTab.rawValue)
            LabeledContent("книг в БД", value: "\(books.count)")
            LabeledContent("читаются", value: "\(books.filter { $0.progress > 0 && $0.progress < 1 }.count)")
            LabeledContent("прочитаны", value: "\(books.filter { $0.isFinished }.count)")
            Picker("Тема", selection: Binding(
                get: { themeStore.currentThemeID },
                set: { try? themeStore.setTheme($0, isPremiumUser: true) }
            )) {
                ForEach(ThemeID.allCases, id: \.self) { id in
                    Text(id.rawValue).tag(id)
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for dest: DebugDestination) -> some View {
        switch dest {
        case .library:
            LibraryView()
        case .reader:
            ReaderView(book: Book.samples[0])
        case .online:
            OnlineView()
        case .settings:
            SettingsView()
        case .cloud:
            CloudStorageView()
        case .reading:
            ReadingView()
        case .bookCards:
            DebugBookCardsScreen()
        case .bookRows:
            DebugBookRowsScreen()
        case .catalogRows:
            DebugCatalogRowsScreen()
        }
    }
}

enum DebugDestination: Hashable {
    case library, reader, online, settings, cloud, reading
    case bookCards, bookRows, catalogRows
}

struct DebugNavRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct DebugBookCardsScreen: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 16)], spacing: 20) {
                ForEach(Book.samples) { book in
                    BookCardView(book: book)
                }
            }
            .padding(20)
        }
        .navigationTitle("BookCardView")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct DebugBookRowsScreen: View {
    var body: some View {
        List(Book.samples) { book in
            BookRow(book: book)
        }
        .navigationTitle("BookRow")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct DebugCatalogRowsScreen: View {
    var body: some View {
        List {
            CatalogRow(icon: "books.vertical.fill", label: "Project Gutenberg",
                       detail: "70 000+ бесплатных книг", color: .green, isConnected: true)
            CatalogRow(icon: "cart.fill", label: "Литрес",
                       detail: "Не подключено", color: .orange, isConnected: false)
            CatalogRow(icon: "globe", label: "OPDS-каталог",
                       detail: "Добавить свой", color: .gray, isConnected: false)
        }
        .navigationTitle("CatalogRow")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    DebugView()
        .modelContainer(for: Book.self, inMemory: true)
}
#endif
