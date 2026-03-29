import Foundation

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
