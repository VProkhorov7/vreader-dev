import Foundation
import Combine

// MARK: - Модель провайдера

struct CloudProviderAccount: Codable, Identifiable {
    let id: UUID
    var providerType: CloudProviderType
    var displayName: String       // "Мой Яндекс.Диск"
    var username: String          // логин (не пароль!)
    var isPremium: Bool

    // Ключ для Keychain: "provider_yandex_uuid"
    var keychainKey: String {
        "provider_\(providerType.rawValue)_\(id.uuidString)"
    }
}

enum CloudProviderType: String, Codable, CaseIterable {
    case iCloudDrive = "icloud"
    case yandexDisk  = "yandex"
    case googleDrive = "google"
    case dropbox     = "dropbox"
    case oneDrive    = "onedrive"
    case webdav      = "webdav"

    var displayName: String {
        switch self {
        case .iCloudDrive: return "iCloud Drive"
        case .yandexDisk:  return "Яндекс.Диск"
        case .googleDrive: return "Google Drive"
        case .dropbox:     return "Dropbox"
        case .oneDrive:    return "OneDrive"
        case .webdav:      return "WebDAV"
        }
    }

    var systemImage: String {
        switch self {
        case .iCloudDrive: return "icloud"
        case .yandexDisk:  return "y.circle"
        case .googleDrive: return "g.circle"
        case .dropbox:     return "archivebox"
        case .oneDrive:    return "cloud"
        case .webdav:      return "server.rack"
        }
    }

    var isPremiumOnly: Bool {
        switch self {
        case .iCloudDrive: return false
        default:           return true
        }
    }
}

// MARK: - Хранилище

@MainActor
final class iCloudSettingsStore: ObservableObject {
    static let shared = iCloudSettingsStore()

    private let store = NSUbiquitousKeyValueStore.default
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Настройки чтения

    @Published var fontSize: Double {
        didSet { store.set(fontSize, forKey: Keys.fontSize) }
    }
    @Published var lineSpacing: Double {
        didSet { store.set(lineSpacing, forKey: Keys.lineSpacing) }
    }
    @Published var fontName: String {
        didSet { store.set(fontName, forKey: Keys.fontName) }
    }
    @Published var readerTheme: String {
        didSet { store.set(readerTheme, forKey: Keys.readerTheme) }
    }

    // MARK: - Подключённые облака

    @Published var connectedAccounts: [CloudProviderAccount] = [] {
        didSet { saveAccounts() }
    }

    // MARK: - Premium

    @Published var isPremium: Bool {
        didSet { store.set(isPremium, forKey: Keys.isPremium) }
    }

    // MARK: - Init

    private init() {
        // Читаем сохранённые значения или дефолты
        fontSize     = store.double(forKey: Keys.fontSize).nonZero ?? 17
        lineSpacing  = store.double(forKey: Keys.lineSpacing).nonZero ?? 1.4
        fontName     = store.string(forKey: Keys.fontName) ?? "Georgia"
        readerTheme  = store.string(forKey: Keys.readerTheme) ?? "light"
        isPremium    = store.bool(forKey: Keys.isPremium)
        connectedAccounts = loadAccounts()

        // Слушаем изменения с других устройств
        NotificationCenter.default.publisher(
            for: NSUbiquitousKeyValueStore.didChangeExternallyNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            self?.handleExternalChange(notification)
        }
        .store(in: &cancellables)

        store.synchronize()
    }

    // MARK: - Аккаунты

    private func saveAccounts() {
        guard let data = try? JSONEncoder().encode(connectedAccounts) else { return }
        store.set(data, forKey: Keys.connectedAccounts)
    }

    private func loadAccounts() -> [CloudProviderAccount] {
        guard let data = store.data(forKey: Keys.connectedAccounts),
              let accounts = try? JSONDecoder().decode([CloudProviderAccount].self, from: data)
        else { return [] }
        return accounts
    }

    // MARK: - Добавить / удалить аккаунт

    func addAccount(_ account: CloudProviderAccount, password: String) throws {
        guard !account.providerType.isPremiumOnly || isPremium else {
            throw SettingsError.premiumRequired
        }
        try KeychainManager.shared.save(password, for: account.keychainKey)
        connectedAccounts.append(account)
    }

    func removeAccount(_ account: CloudProviderAccount) {
        _ = try? KeychainManager.shared.delete(key: account.keychainKey)
        connectedAccounts.removeAll { $0.id == account.id }
    }

    func password(for account: CloudProviderAccount) -> String? {
        try? KeychainManager.shared.read(key: account.keychainKey)
    }

    // MARK: - Внешние изменения (другое устройство)

    private func handleExternalChange(_ notification: Notification) {
        fontSize     = store.double(forKey: Keys.fontSize).nonZero ?? fontSize
        lineSpacing  = store.double(forKey: Keys.lineSpacing).nonZero ?? lineSpacing
        fontName     = store.string(forKey: Keys.fontName) ?? fontName
        readerTheme  = store.string(forKey: Keys.readerTheme) ?? readerTheme
        isPremium    = store.bool(forKey: Keys.isPremium)
        connectedAccounts = loadAccounts()
    }
}

// MARK: - Ошибки

enum SettingsError: LocalizedError {
    case premiumRequired
    var errorDescription: String? {
        "Эта функция доступна только в Premium версии"
    }
}

// MARK: - Ключи

private enum Keys {
    static let fontSize          = "reader.fontSize"
    static let lineSpacing       = "reader.lineSpacing"
    static let fontName          = "reader.fontName"
    static let readerTheme       = "reader.readerTheme"
    static let isPremium         = "app.isPremium"
    static let connectedAccounts = "cloud.connectedAccounts"
}

// MARK: - Helper

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
