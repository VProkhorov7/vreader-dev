import SwiftUI

struct OnlineView: View {
    var body: some View {
        List {

            // Бесплатные
            Section {
                CatalogRow(icon: "books.vertical.fill",
                           label: "Project Gutenberg",
                           detail: "70 000+ бесплатных книг",
                           color: .green,
                           isConnected: true)
                CatalogRow(icon: "books.vertical.fill",
                           label: "Standard Ebooks",
                           detail: "Качественные public domain",
                           color: .teal,
                           isConnected: true)
                CatalogRow(icon: "books.vertical.fill",
                           label: "Manybooks",
                           detail: "Бесплатные EPUB / FB2",
                           color: .mint,
                           isConnected: true)
            } header: {
                Label("Бесплатные", systemImage: "gift")
            }

            // Магазины
            Section {
                CatalogRow(icon: "cart.fill",
                           label: "Литрес",
                           detail: "Не подключено",
                           color: .orange,
                           isConnected: false)
                CatalogRow(icon: "cart.fill",
                           label: "Google Play Books",
                           detail: "Не подключено",
                           color: Color(red: 0.26, green: 0.52, blue: 0.96),
                           isConnected: false)
                CatalogRow(icon: "cart.fill",
                           label: "Amazon Kindle",
                           detail: "Не подключено",
                           color: Color(red: 1.0, green: 0.6, blue: 0.0),
                           isConnected: false)
            } header: {
                Label("Магазины", systemImage: "cart")
            }

            // OPDS-каталоги
            Section {
                CatalogRow(icon: "globe",
                           label: "Флибуста",
                           detail: "Не подключено",
                           color: .purple,
                           isConnected: false)
                CatalogRow(icon: "globe",
                           label: "OPDS-каталог",
                           detail: "Добавить свой",
                           color: .gray,
                           isConnected: false)
            } header: {
                Label("OPDS", systemImage: "antenna.radiowaves.left.and.right")
            }
        }
        .navigationTitle(Text("tab.online"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // TODO: добавить каталог
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - CatalogRow

struct CatalogRow: View {
    let icon: String
    let label: String
    let detail: String
    let color: Color
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(isConnected ? 1.0 : 0.25))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 16))
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("\(label), \(detail)")
    }
}

#Preview {
    NavigationStack {
        OnlineView()
    }
}
