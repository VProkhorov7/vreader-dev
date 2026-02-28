import SwiftUI

struct StoragesView: View {
    var body: some View {
        List {

            // MARK: Локальные
            Section {
                StorageRow(icon: "internaldrive.fill",
                           label: "На устройстве",
                           detail: "3 папки · 142 книги",
                           color: .gray,
                           isConnected: true)
                StorageRow(icon: "icloud.fill",
                           label: "iCloud Drive",
                           detail: "1 папка · 38 книг",
                           color: .blue,
                           isConnected: true)
            } header: {
                Label("Локальные", systemImage: "internaldrive")
            }

            // MARK: Сетевые
            Section {
                StorageRow(icon: "externaldrive.fill",
                           label: "SMB / NAS",
                           detail: "Не подключено",
                           color: .orange,
                           isConnected: false)
                StorageRow(icon: "server.rack",
                           label: "WebDAV",
                           detail: "Не подключено",
                           color: .brown,
                           isConnected: false)
                StorageRow(icon: "bonjour",
                           label: "Bonjour / UPnP",
                           detail: "Не подключено",
                           color: .teal,
                           isConnected: false)
            } header: {
                Label("Сетевые", systemImage: "network")
            }

            // MARK: Интернет
            Section {
                StorageRow(icon: "cloud.fill",
                           label: "Dropbox",
                           detail: "Не подключено",
                           color: .blue,
                           isConnected: false)
                StorageRow(icon: "cloud.fill",
                           label: "Google Drive",
                           detail: "Не подключено",
                           color: Color(red: 0.26, green: 0.52, blue: 0.96),
                           isConnected: false)
                StorageRow(icon: "cloud.fill",
                           label: "Яндекс Диск",
                           detail: "Не подключено",
                           color: .red,
                           isConnected: false)
                StorageRow(icon: "cloud.fill",
                           label: "Amazon S3",
                           detail: "Не подключено",
                           color: Color(red: 1.0, green: 0.6, blue: 0.0),
                           isConnected: false)
                StorageRow(icon: "cloud.fill",
                           label: "OneDrive",
                           detail: "Не подключено",
                           color: Color(red: 0.0, green: 0.47, blue: 0.84),
                           isConnected: false)
            } header: {
                Label("Интернет", systemImage: "globe")
            }
        }
        .navigationTitle(Text("tab.storages"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // TODO: добавить хранилище
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - StorageRow

struct StorageRow: View {
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
                    .foregroundStyle(isConnected ? .primary : .primary)
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
        StoragesView()
    }
}
