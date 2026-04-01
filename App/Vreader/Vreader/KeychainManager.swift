import Foundation
import Security
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.vreader.app", category: "KeychainManager")

// MARK: - KeychainKey

enum KeychainKey {
    case geminiAPIKey
    case googleDriveAccessToken
    case googleDriveRefreshToken
    case dropboxAccessToken
    case dropboxRefreshToken
    case oneDriveAccessToken
    case oneDriveRefreshToken
    case webDAVPassword(host: String)
    case smbPassword(host: String)

    private static let bundleID = Bundle.main.bundleIdentifier ?? "com.vreader.app"

    var isSynchronizable: Bool {
        switch self {
        case .googleDriveAccessToken,
             .googleDriveRefreshToken,
             .dropboxAccessToken,
             .dropboxRefreshToken,
             .oneDriveAccessToken,
             .oneDriveRefreshToken:
            return true
        case .geminiAPIKey,
             .webDAVPassword,
             .smbPassword:
            return false
        }
    }

    var service: String {
        switch self {
        case .webDAVPassword:
            return Self.bundleID + ".webdav"
        case .smbPassword:
            return Self.bundleID + ".smb"
        default:
            return Self.bundleID
        }
    }

    var account: String {
        switch self {
        case .geminiAPIKey:
            return "geminiAPIKey"
        case .googleDriveAccessToken:
            return "googleDriveAccessToken"
        case .googleDriveRefreshToken:
            return "googleDriveRefreshToken"
        case .dropboxAccessToken:
            return "dropboxAccessToken"
        case .dropboxRefreshToken:
            return "dropboxRefreshToken"
        case .oneDriveAccessToken:
            return "oneDriveAccessToken"
        case .oneDriveRefreshToken:
            return "oneDriveRefreshToken"
        case .webDAVPassword(let host):
            return host
        case .smbPassword(let host):
            return host
        }
    }

    var displayName: String {
        switch self {
        case .geminiAPIKey:              return "geminiAPIKey"
        case .googleDriveAccessToken:    return "googleDriveAccessToken"
        case .googleDriveRefreshToken:   return "googleDriveRefreshToken"
        case .dropboxAccessToken:        return "dropboxAccessToken"
        case .dropboxRefreshToken:       return "dropboxRefreshToken"
        case .oneDriveAccessToken:       return "oneDriveAccessToken"
        case .oneDriveRefreshToken:      return "oneDriveRefreshToken"
        case .webDAVPassword:            return "webDAVPassword"
        case .smbPassword:               return "smbPassword"
        }
    }
}

// MARK: - KeychainManager

actor KeychainManager {

    static let shared = KeychainManager()

    private static let sentinelKey = "keychainDidInitialize"
    private let appGroupID: String?

    private init(appGroupID: String? = nil) {
        self.appGroupID = appGroupID
        if !UserDefaults.standard.bool(forKey: Self.sentinelKey) {
            KeychainManager.performDeleteAll(appGroupID: appGroupID)
            UserDefaults.standard.set(true, forKey: Self.sentinelKey)
            logger.info("KeychainManager: first-launch cleanup completed")
        }
    }

    // MARK: - Save String

    func save(key: KeychainKey, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AppError.make(.keychainAccessFailed)
        }
        try save(key: key, data: data)
    }

    // MARK: - Load String

    func load(key: KeychainKey) throws -> String? {
        guard let data: Data = try load(key: key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            logger.error("KeychainManager: failed to decode string for key=\(key.displayName, privacy: .public)")
            throw AppError.make(.keychainAccessFailed)
        }
        return string
    }

    // MARK: - Save Data

    func save(key: KeychainKey, data: Data) throws {
        var query = baseQuery(for: key)
        query[kSecValueData as String] = data

        let addStatus = SecItemAdd(query as CFDictionary, nil)

        if addStatus == errSecSuccess {
            logger.info("KeychainManager: saved key=\(key.displayName, privacy: .public)")
            return
        }

        if addStatus == errSecDuplicateItem {
            let searchQuery = searchQuery(for: key)
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            let updateStatus = SecItemUpdate(searchQuery as CFDictionary, updateAttributes as CFDictionary)
            if updateStatus == errSecSuccess {
                logger.info("KeychainManager: updated key=\(key.displayName, privacy: .public)")
                return
            }
            logger.error("KeychainManager: update failed key=\(key.displayName, privacy: .public) status=\(updateStatus, privacy: .public)")
            throw AppError.make(.keychainAccessFailed)
        }

        logger.error("KeychainManager: add failed key=\(key.displayName, privacy: .public) status=\(addStatus, privacy: .public)")
        throw AppError.make(.keychainAccessFailed)
    }

    // MARK: - Load Data

    func load(key: KeychainKey) throws -> Data? {
        var query = searchQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            logger.error("KeychainManager: load failed key=\(key.displayName, privacy: .public) status=\(status, privacy: .public)")
            throw AppError.make(.keychainAccessFailed)
        }

        guard let data = result as? Data else {
            logger.error("KeychainManager: unexpected data format key=\(key.displayName, privacy: .public)")
            throw AppError.make(.keychainAccessFailed)
        }

        return data
    }

    // MARK: - Delete

    func delete(key: KeychainKey) throws {
        let query = searchQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        if status == errSecItemNotFound || status == errSecSuccess {
            logger.info("KeychainManager: deleted key=\(key.displayName, privacy: .public)")
            return
        }

        logger.error("KeychainManager: delete failed key=\(key.displayName, privacy: .public) status=\(status, privacy: .public)")
        throw AppError.make(.keychainAccessFailed)
    }

    // MARK: - Exists

    func exists(key: KeychainKey) -> Bool {
        var query = searchQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Delete All

    func deleteAll() {
        KeychainManager.performDeleteAll(appGroupID: appGroupID)
    }

    // MARK: - Private Helpers

    private func baseQuery(for key: KeychainKey) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     key.service,
            kSecAttrAccount as String:     key.account,
            kSecAttrAccessible as String:  kSecAttrAccessibleAfterFirstUnlock
        ]

        let syncValue: CFBoolean = key.isSynchronizable ? kCFBooleanTrue : kCFBooleanFalse
        query[kSecAttrSynchronizable as String] = syncValue

        if let groupID = appGroupID {
            query[kSecAttrAccessGroup as String] = groupID
        }

        return query
    }

    private func searchQuery(for key: KeychainKey) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String:              kSecClassGenericPassword,
            kSecAttrService as String:        key.service,
            kSecAttrAccount as String:        key.account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]

        if let groupID = appGroupID {
            query[kSecAttrAccessGroup as String] = groupID
        }

        return query
    }

    private static func performDeleteAll(appGroupID: String?) {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.vreader.app"

        let services: [String] = [
            bundleID,
            bundleID + ".webdav",
            bundleID + ".smb"
        ]

        for service in services {
            var query: [String: Any] = [
                kSecClass as String:              kSecClassGenericPassword,
                kSecAttrService as String:        service,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
            ]
            if let groupID = appGroupID {
                query[kSecAttrAccessGroup as String] = groupID
            }
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                logger.warning("KeychainManager: deleteAll partial failure service=\(service, privacy: .public) status=\(status, privacy: .public)")
            }
        }

        logger.info("KeychainManager: deleteAll completed")
    }
}