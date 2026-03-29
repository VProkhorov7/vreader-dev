import Foundation
import Combine
import SwiftUI

// MARK: - CloudProviderAccount

struct CloudProviderAccount: Identifiable {
    let id: UUID
    var providerType: CloudProviderType
    var displayName: String
    var host: String
    var username: String
    var isPremium: Bool

    var keychainKey: String { "provider_\(providerType.rawValue)_\(id.uuidString)" }
}

// Кастомный Codable: host совместим со старыми данными без этого поля
extension CloudProviderAccount: Codable {
    enum CodingKeys: String, CodingKey {
        case id, providerType, displayName, host, username, isPremium
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try  c.decode(UUID.self,              forKey: .id)
        providerType = try  c.decode(CloudProviderType.self, forKey: .providerType)
        displayName  = try  c.decode(String.self,            forKey: .displayName)
        host         = (try? c.decode(String.self,           forKey: .host)) ?? ""
        username     = try  c.decode(String.self,            forKey: .username)
        isPremium    = (try? c.decode(Bool.self,             forKey: .isPremium)) ?? false
    }
}

// MARK: - OnlineCatalogEntry

struct OnlineCatalogEntry: Codable, Identifiable {
    let id: UUID
    var catalogID: String
    var displayName: String
    var url: String
    var login: String

    var keychainKey: String { "catalog_\(id.uuidString)" }
}

// MARK: - CloudProviderType

enum CloudProviderType: String, Codable, CaseIterable {
    case iCloudDrive = "icloud"
    case yandexDisk  = "yandex"
    case googleDrive = "google"
    case dropbox     = "dropbox"
    case oneDrive    = "onedrive"
    case nextcloud   = "nextcloud"
    case webdav      = "webdav"
    case mailru      = "mailru"
    case smb         = "smb"

    var displayName: String {
        switch self {
        case .iCloudDrive: return "iCloud Drive"
        case .yandexDisk:  return "Яндекс.Диск"
        case .googleDrive: return "Google Drive"
        case .dropbox:     return "Dropbox"
        case .oneDrive:    return "OneDrive"
        case .nextcloud:   return "Nextcloud"
        case .webdav:      return "WebDAV"
        case .mailru:      return "Облако Mail.ru"
        case .smb:         return "SMB / Samba"
        }
    }

    var systemImage: String {
        switch self {
        case .iCloudDrive: return "icloud.fill"
        case .yandexDisk:  return "y.circle.fill"
        case .googleDrive: return "g.circle.fill"
        case .dropbox:     return "archivebox.fill"
        case .oneDrive:    return "cloud.fill"
        case .nextcloud:   return "cloud.circle.fill"
        case .webdav:      return "server.rack"
        case .mailru:      return "envelope.fill"
        case .smb:         return "network"
        }
    }

    var color: Color {
        switch self {
        case .iCloudDrive: return Color(red: 0.0,  green: 0.48, blue: 1.0)
        case .yandexDisk:  return Color(red: 1.0,  green: 0.2,  blue: 0.2)
        case .googleDrive: return Color(red: 0.26, green: 0.52, blue: 0.96)
        case .dropbox:     return Color(red: 0.0,  green: 0.4,  blue: 1.0)
        case .oneDrive:    return Color(red: 0.0,  green: 0.47, blue: 0.84)
        case .nextcloud:   return Color(red: 0.1,  green: 0.5,  blue: 0.9)
        case .webdav:      return Color(white: 0.45)
        case .mailru:      return Color(red: 0.0,  green: 0.44, blue: 0.88)
        case .smb:         return Color(red: 0.3,  green: 0.3,  blue: 0.5)
        }
    }

    var defaultHost: String {
        switch self {
        case .iCloudDrive: return ""
        case .yandexDisk:  return "https://webdav.yandex.ru"
        case .googleDrive, .dropbox, .oneDrive: return ""
        case .nextcloud:   return "https://your-nextcloud.com/remote.php/dav/files/"
        case .webdav:      return "https://"
        case .mailru:      return "https://webdav.cloud.mail.ru"
        case .smb:         return "smb://192.168.1."
        }
    }

    var helpText: String {
        switch self {
        case .iCloudDrive: return "Встроено в систему, пароль не нужен"
        case .yandexDisk:  return "Используй Пароль приложения (Яндекс ID → Безопасность)"
        case .googleDrive: return "OAuth — появится в следующем обновлении"
        case .dropbox:     return "OAuth — появится в следующем обновлении"
        case .oneDrive:    return "OAuth — появится в следующем обновлении"
        case .nextcloud:   return "Адрес сервера + логин/пароль Nextcloud"
        case .webdav:      return "Любой WebDAV-совместимый сервер (Calibre, Nginx и др.)"
        case .mailru:      return "Только платный тариф. Создай Пароль приложения в настройках Mail.ru"
        case .smb:         return "IP компьютера в локальной сети, например smb://192.168.1.10"
        }
    }

    var usesWebDAV: Bool {
        switch self {
        case .yandexDisk, .nextcloud, .webdav, .mailru: return true
        default: return false
        }
    }

    var isPremiumOnly: Bool { false }
}

// MARK: - Settings Store (UserDefaults — не требует entitlement)

@MainActor
final class iCloudSettingsStore: ObservableObject {
    static let shared = iCloudSettingsStore()

    private let defaults = UserDefaults.standard

    @Published var fontSize: Double        { didSet { defaults.set(fontSize,         forKey: Keys.fontSize) } }
    @Published var lineSpacing: Double     { didSet { defaults.set(lineSpacing,       forKey: Keys.lineSpacing) } }
    @Published var fontName: String        { didSet { defaults.set(fontName,          forKey: Keys.fontName) } }
    @Published var readerTheme: String     { didSet { defaults.set(readerTheme,       forKey: Keys.readerTheme) } }
    @Published var scrollMode: String      { didSet { defaults.set(scrollMode,        forKey: Keys.scrollMode) } }
    @Published var verticalTextMode: Bool  { didSet { defaults.set(verticalTextMode,  forKey: Keys.verticalTextMode) } }
    @Published var isPremium: Bool         { didSet { defaults.set(isPremium,         forKey: Keys.isPremium) } }

    @Published var connectedAccounts: [CloudProviderAccount] = [] {
        didSet { saveAccounts() }
    }
    @Published var connectedCatalogs: [OnlineCatalogEntry] = [] {
        didSet { saveCatalogs() }
    }

    private init() {
        fontSize         = defaults.double(forKey: Keys.fontSize).nonZero  ?? 17
        lineSpacing      = defaults.double(forKey: Keys.lineSpacing).nonZero ?? 1.4
        fontName         = defaults.string(forKey: Keys.fontName)   ?? "Georgia"
        readerTheme      = defaults.string(forKey: Keys.readerTheme) ?? "light"
        scrollMode       = defaults.string(forKey: Keys.scrollMode)  ?? "page_horizontal"
        verticalTextMode = defaults.bool(forKey: Keys.verticalTextMode)
        isPremium        = defaults.bool(forKey: Keys.isPremium)
        connectedAccounts = loadAccounts()
        connectedCatalogs = loadCatalogs()
    }

    // MARK: Accounts

    private func saveAccounts() {
        guard let data = try? JSONEncoder().encode(connectedAccounts) else { return }
        defaults.set(data, forKey: Keys.connectedAccounts)
    }

    private func loadAccounts() -> [CloudProviderAccount] {
        guard let data = defaults.data(forKey: Keys.connectedAccounts),
              let list = try? JSONDecoder().decode([CloudProviderAccount].self, from: data)
        else { return [] }
        return list
    }

    func addAccount(_ account: CloudProviderAccount, password: String) throws {
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

    // MARK: Catalogs

    private func saveCatalogs() {
        guard let data = try? JSONEncoder().encode(connectedCatalogs) else { return }
        defaults.set(data, forKey: Keys.connectedCatalogs)
    }

    private func loadCatalogs() -> [OnlineCatalogEntry] {
        guard let data = defaults.data(forKey: Keys.connectedCatalogs),
              let list = try? JSONDecoder().decode([OnlineCatalogEntry].self, from: data)
        else { return [] }
        return list
    }

    func addCatalog(_ entry: OnlineCatalogEntry, password: String = "") throws {
        if !password.isEmpty {
            try KeychainManager.shared.save(password, for: entry.keychainKey)
        }
        connectedCatalogs.append(entry)
    }

    func removeCatalog(_ entry: OnlineCatalogEntry) {
        _ = try? KeychainManager.shared.delete(key: entry.keychainKey)
        connectedCatalogs.removeAll { $0.id == entry.id }
    }

    func catalogPassword(for entry: OnlineCatalogEntry) -> String? {
        try? KeychainManager.shared.read(key: entry.keychainKey)
    }

    func isCatalogConnected(_ catalogID: String) -> Bool {
        connectedCatalogs.contains { $0.catalogID == catalogID }
    }
}

enum SettingsError: LocalizedError {
    case premiumRequired
    var errorDescription: String? { "Эта функция доступна только в Premium версии" }
}

private enum Keys {
    static let fontSize          = "reader.fontSize"
    static let lineSpacing       = "reader.lineSpacing"
    static let fontName          = "reader.fontName"
    static let readerTheme       = "reader.readerTheme"
    static let scrollMode        = "reader.scrollMode"
    static let verticalTextMode  = "reader.verticalTextMode"
    static let isPremium         = "app.isPremium"
    static let connectedAccounts = "cloud.connectedAccounts"
    static let connectedCatalogs = "cloud.connectedCatalogs"
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
