import Foundation
import SwiftUI

// MARK: - Shelf / Collections

struct ShelfID: Hashable, Codable {
    let rawValue: String
}

struct ShelfCategory: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var sortOrder: Int
}

struct Shelf: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var categoryID: ShelfCategory.ID?
    var sortOrder: Int
    var bookIDs: [UUID]           // ← было [BookID], теперь просто [UUID]
}

// MARK: - Storages (Files / Sources)

struct StorageID: Hashable, Codable {
    let rawValue: String  // e.g. "gdrive-default", "smb/nas-books"
}

enum StorageKind: String, Codable {
    // Локальные
    case local
    case iCloud

    // Сетевые
    case smb
    case webDAV
    case bonjour

    // Интернет
    case dropbox
    case googleDrive
    case yandexDisk
    case amazonS3
    case oneDrive
}

struct StorageSource: Identifiable, Codable {
    let id: StorageID
    var kind: StorageKind
    var displayName: String
    var rootPath: String
    var isConnected: Bool
}

struct StorageFolderID: Hashable, Codable {
    let rawValue: String  // storageID + path
}

struct StorageFolder: Identifiable, Hashable, Codable {
    let id: StorageFolderID
    var storageID: StorageID
    var path: String
    var name: String
    var childFolderCount: Int?
    var bookIDs: [UUID]           // ← было [BookID], теперь просто [UUID]
    var isCached: Bool
}

// MARK: - Online Catalogs (OPDS / Services)

struct OnlineCatalogID: Hashable, Codable {
    let rawValue: String
}

enum OnlineCatalogKind: String, Codable {
    case opds
    case litres
    case gutenberg
    case custom
}

// MARK: - Online Catalog Entry

struct OnlineCatalogEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var catalogID: String
    var displayName: String
    var url: String
    var login: String
}

// MARK: - Cloud Provider Type

enum CloudProviderType: String, Hashable, Codable, CaseIterable {
    case yandexDisk
    case mailru
    case nextcloud
    case webdav
    case smb
    case iCloudDrive

    var displayName: String {
        switch self {
        case .yandexDisk:   return "Яндекс.Диск"
        case .mailru:       return "Облако Mail.ru"
        case .nextcloud:    return "Nextcloud"
        case .webdav:       return "WebDAV"
        case .smb:          return "SMB (локальная сеть)"
        case .iCloudDrive:  return "iCloud Drive"
        }
    }

    var systemImage: String {
        switch self {
        case .yandexDisk:   return "cloud.fill"
        case .mailru:       return "cloud.fill"
        case .nextcloud:    return "externaldrive.connected.to.line.below.fill"
        case .webdav:       return "server.rack"
        case .smb:          return "network"
        case .iCloudDrive:  return "icloud.fill"
        }
    }

    var color: Color {
        switch self {
        case .yandexDisk:   return .red
        case .mailru:       return .orange
        case .nextcloud:    return .blue
        case .webdav:       return .purple
        case .smb:          return .gray
        case .iCloudDrive:  return .blue
        }
    }

    var defaultHost: String {
        switch self {
        case .yandexDisk:   return "https://webdav.yandex.ru"
        case .mailru:       return "https://webdav.cloud.mail.ru"
        case .nextcloud:    return "https://"
        case .webdav:       return "https://"
        case .smb:          return ""
        case .iCloudDrive:  return ""
        }
    }

    var helpText: String {
        switch self {
        case .yandexDisk:
            return "Используйте пароль приложения, а не пароль аккаунта."
        case .mailru:
            return "Используйте внешний пароль из настроек Mail.ru."
        case .nextcloud:
            return "Введите адрес вашего сервера Nextcloud."
        case .webdav:
            return "Введите URL WebDAV-сервера."
        case .smb:
            return "Введите адрес сетевой папки."
        case .iCloudDrive:
            return ""
        }
    }
}

// MARK: - Cloud Provider Account

struct CloudProviderAccount: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var providerType: CloudProviderType
    var displayName: String
    var host: String
    var username: String
    var isPremium: Bool
}
