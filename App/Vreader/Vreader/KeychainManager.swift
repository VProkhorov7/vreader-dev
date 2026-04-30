import Foundation
import OSLog
import Security

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

    var rawValue: String {
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
            return "webDAVPassword.\(host)"
        case .smbPassword(let host):
            return "smbPassword.\(host)"
        }
    }

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

    var accessibility: CFString {
        isSynchronizable
            ? kSecAttrAccessibleAfterFirstUnlock
            : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    }
}

actor KeychainManager {
    static let shared = KeychainManager()

    private let service: String
    private let accessGroup: String?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.vreader.app", category: "KeychainManager")

    init(accessGroup: String? = nil) {
        self.service = Bundle.main.bundleIdentifier ?? "com.vreader.app"
        self.accessGroup = accessGroup
    }

    private func accountString(prefix: String, rawKey: String) -> String {
        "\(prefix):\(rawKey)"
    }

    private func buildBaseQuery(account: String, synchronizable: Bool, accessibility: CFString) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: accessibility,
            kSecAttrSynchronizable as String: synchronizable ? kCFBooleanTrue! : kCFBooleanFalse!
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

    private func buildLookupQuery(account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

    private func buildDeleteQuery(account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

    private func buildExistsQuery(account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

    private func performSave(account: String, data: Data, synchronizable: Bool, accessibility: CFString) throws {
        let deleteQuery = buildDeleteQuery(account: account)
        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            logger.warning("KeychainManager: pre-delete failed for account=\(account, privacy: .public) status=\(deleteStatus)")
        }

        var addQuery = buildBaseQuery(account: account, synchronizable: synchronizable, accessibility: accessibility)
        addQuery[kSecValueData as String] = data

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            logger.error("KeychainManager: save failed for account=\(account, privacy: .public) status=\(status)")
            throw AppError(
                code: .auth(.keychainUnavailable),
                description: "Keychain save failed.",
                recoveryHint: "Ensure the app has Keychain access and try again."
            )
        }
    }

    private func performLoad(account: String) throws -> Data {
        let query = buildLookupQuery(account: account)
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            logger.info("KeychainManager: item not found for account=\(account, privacy: .public)")
            throw AppError(
                code: .auth(.credentialsMissing),
                description: "Credential not found in Keychain.",
                recoveryHint: "Please re-enter your credentials."
            )
        }

        guard status == errSecSuccess else {
            logger.error("KeychainManager: load failed for account=\(account, privacy: .public) status=\(status)")
            throw AppError(
                code: .auth(.keychainUnavailable),
                description: "Keychain load failed.",
                recoveryHint: "Ensure the app has Keychain access and try again."
            )
        }

        guard let data = result as? Data else {
            logger.error("KeychainManager: unexpected data format for account=\(account, privacy: .public)")
            throw AppError(
                code: .auth(.keychainUnavailable),
                description: "Keychain returned unexpected data format.",
                recoveryHint: "Try deleting and re-entering your credentials."
            )
        }

        return data
    }

    private func performDelete(account: String) throws {
        let query = buildDeleteQuery(account: account)
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound {
            return
        }
        guard status == errSecSuccess else {
            logger.error("KeychainManager: delete failed for account=\(account, privacy: .public) status=\(status)")
            throw AppError(
                code: .auth(.keychainUnavailable),
                description: "Keychain delete failed.",
                recoveryHint: "Ensure the app has Keychain access and try again."
            )
        }
    }

    private func performExists(account: String) -> Bool {
        let query = buildExistsQuery(account: account)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AppError(
                code: .auth(.keychainUnavailable),
                description: "Failed to encode string value for Keychain.",
                recoveryHint: "Ensure the value contains valid UTF-8 characters."
            )
        }
        let account = accountString(prefix: "str", rawKey: key)
        try performSave(
            account: account,
            data: data,
            synchronizable: false,
            accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        )
    }

    func load(key: String) throws -> String {
        let account = accountString(prefix: "str", rawKey: key)
        let data = try performLoad(account: account)
        guard let string = String(data: data, encoding: .utf8) else {
            logger.error("KeychainManager: UTF-8 decode failed for account=\(account, privacy: .public)")
            throw AppError(
                code: .auth(.keychainUnavailable),
                description: "Failed to decode Keychain string value.",
                recoveryHint: "Try deleting and re-entering your credentials."
            )
        }
        return string
    }

    func delete(key: String) throws {
        let account = accountString(prefix: "str", rawKey: key)
        try performDelete(account: account)
    }

    func exists(key: String) -> Bool {
        let account = accountString(prefix: "str", rawKey: key)
        return performExists(account: account)
    }

    func save(key: String, data: Data) throws {
        let account = accountString(prefix: "dat", rawKey: key)
        try performSave(
            account: account,
            data: data,
            synchronizable: false,
            accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        )
    }

    func load(key: String) throws -> Data {
        let account = accountString(prefix: "dat", rawKey: key)
        return try performLoad(account: account)
    }

    func save(key: KeychainKey, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AppError(
                code: .auth(.keychainUnavailable),
                description: "Failed to encode string value for Keychain.",
                recoveryHint: "Ensure the value contains valid UTF-8 characters."
            )
        }
        let account = accountString(prefix: "str", rawKey: key.rawValue)
        try performSave(
            account: account,
            data: data,
            synchronizable: key.isSynchronizable,
            accessibility: key.accessibility
        )
    }

    func load(key: KeychainKey) throws -> String {
        let account = accountString(prefix: "str", rawKey: key.rawValue)
        let data = try performLoad(account: account)
        guard let string = String(data: data, encoding: .utf8) else {
            logger.error("KeychainManager: UTF-8 decode failed for account=\(account, privacy: .public)")
            throw AppError(
                code: .auth(.keychainUnavailable),
                description: "Failed to decode Keychain string value.",
                recoveryHint: "Try deleting and re-entering your credentials."
            )
        }
        return string
    }

    func delete(key: KeychainKey) throws {
        let account = accountString(prefix: "str", rawKey: key.rawValue)
        try performDelete(account: account)
    }

    func exists(key: KeychainKey) -> Bool {
        let account = accountString(prefix: "str", rawKey: key.rawValue)
        return performExists(account: account)
    }

    func save(key: KeychainKey, data: Data) throws {
        let account = accountString(prefix: "dat", rawKey: key.rawValue)
        try performSave(
            account: account,
            data: data,
            synchronizable: key.isSynchronizable,
            accessibility: key.accessibility
        )
    }

    func load(key: KeychainKey) throws -> Data {
        let account = accountString(prefix: "dat", rawKey: key.rawValue)
        return try performLoad(account: account)
    }
}