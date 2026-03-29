import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.addedAt, order: .reverse) private var books: [Book]
    @ObservedObject private var store = iCloudSettingsStore.shared

    @State private var showImporter      = false
    @State private var showSourcePicker  = false
    @State private var errorMessage: String?
    @State private var selectedBook: Book?
    @State private var selectedDetail: Book?
    @AppStorage("library.isGrid") private var isGrid = true

    private let gridColumns = [
        GridItem(.adaptive(minimum: 110, maximum: 140), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle(L10n.Library.title)
                .toolbar { toolbarContent }
                .fullScreenCover(item: $selectedBook) { book in
                    ReaderView(book: book)
                }
                .sheet(item: $selectedDetail) { book in
                    BookDetailView(book: book)
                }
                .onAppear {
                    CoverFetcher.shared.fetchAllMissing(books: books, context: modelContext)
                }
                .onChange(of: books.count) {
                    CoverFetcher.shared.fetchAllMissing(books: books, context: modelContext)
                }
                .fileImporter(
                    isPresented: $showImporter,
                    allowedContentTypes: allowedContentTypes,
                    allowsMultipleSelection: true
                ) { result in
                    handleImport(result: result)
                }
                .confirmationDialog(
                    L10n.Library.addBook,
                    isPresented: $showSourcePicker,
                    titleVisibility: .visible
                ) {
                    dialogContent
                } message: {
                    Text(L10n.Library.chooseSource)
                }
                .alert(L10n.Common.error, isPresented: .constant(errorMessage != nil)) {
                    Button("OK") { errorMessage = nil }
                } message: {
                    Text(errorMessage ?? "")
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if books.isEmpty {
            LibraryEmptyState { showSourcePicker = true }
        } else if isGrid {
            gridView
        } else {
            listView
        }
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 20) {
                ForEach(books) { book in
                    bookGridButton(for: book)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var listView: some View {
        List {
            ForEach(books) { book in
                bookListButton(for: book)
            }
            .onDelete(perform: deleteBooks)
        }
    }

    private func bookGridButton(for book: Book) -> some View {
        Button {
            if book.isDownloaded { selectedBook  = book }
            else                 { selectedDetail = book }
        } label: {
            BookCardView(book: book)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { deleteBook(book) } label: {
                Label(L10n.Library.delete, systemImage: "trash")
            }
        }
    }

    private func bookListButton(for book: Book) -> some View {
        Button {
            if book.isDownloaded { selectedBook  = book }
            else                 { selectedDetail = book }
        } label: {
            BookRow(book: book)
        }
        .buttonStyle(.plain)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { showSourcePicker = true } label: {
                Image(systemName: "plus")
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Button { withAnimation { isGrid.toggle() } } label: {
                Image(systemName: isGrid ? "list.bullet" : "square.grid.2x2")
            }
        }
    }

    @ViewBuilder
    private var dialogContent: some View {
        Button(L10n.Library.fromDevice) { showImporter = true }
        ForEach(store.connectedAccounts) { account in
            Button(String(format: NSLocalizedString(
                "library.from_account", value: "Из %@", comment: ""
            ), account.displayName)) {}
        }
        Button(L10n.Common.cancel, role: .cancel) {}
    }

    // ── Безопасная инициализация UTType: никаких force-unwrap ──
    private var allowedContentTypes: [UTType] {
        var types: [UTType] = [.pdf, .epub, .plainText, .rtf, .mp3, .mpeg4Audio]
        let extensions = [
            "fb2", "fb2.zip", "cbz", "cbr", "cb7", "cbt",
            "mobi", "azw3", "djvu", "chm", "m4b"
        ]
        for ext in extensions {
            if let t = UTType(filenameExtension: ext) { types.append(t) }
        }
        return types
    }

    private func deleteBook(_ book: Book) {
        if let url = book.fileURL { try? FileManager.default.removeItem(at: url) }
        modelContext.delete(book)
    }

    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets { deleteBook(books[index]) }
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
}

// MARK: - BookRow

struct BookRow: View {
    let book: Book

    private var placeholderIcon: some View {
        Image(systemName: book.formatIcon)
            .font(.title2)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.accentColor.gradient)
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let path = book.coverPath {
                    #if canImport(UIKit)
                    if let img = UIImage(contentsOfFile: path) {
                        Image(uiImage: img).resizable().scaledToFill()
                    } else { placeholderIcon }
                    #elseif canImport(AppKit)
                    if let img = NSImage(contentsOfFile: path) {
                        Image(nsImage: img).resizable().scaledToFill()
                    } else { placeholderIcon }
                    #endif
                } else {
                    placeholderIcon
                }
            }
            .frame(width: 48, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title).font(.headline).lineLimit(2)
                Text(book.author).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                if book.progress > 0 {
                    ProgressView(value: min(1, max(0, book.progress))).tint(Color.accentColor)
                    Text("\(book.progressPercent)%").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(book.format.uppercased())
                .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                .background(.quaternary).clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - LibraryEmptyState

struct LibraryEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.08)).frame(width: 120, height: 120)
                Circle().fill(Color.accentColor.opacity(0.05)).frame(width: 160, height: 160)
                Image(systemName: "books.vertical")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Color.accentColor.opacity(0.7))
            }
            .padding(.bottom, 28)

            Text(L10n.Library.emptyTitle)
                .font(.system(size: 22, weight: .semibold)).foregroundStyle(.primary)
                .padding(.bottom, 8)
            Text(L10n.Library.emptyMessage)
                .font(.system(size: 15)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineSpacing(3).padding(.bottom, 36)

            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                    Text(L10n.Library.addBook).font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24).padding(.vertical, 13)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}
