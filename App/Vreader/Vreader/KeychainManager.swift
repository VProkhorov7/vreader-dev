import Foundation
import Security

// MARK: - Ошибки

enum KeychainError: LocalizedError {
    case unexpectedData
    case unhandledError(status: OSStatus)
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .unexpectedData:       return "Неверный формат данных в Keychain"
        case .itemNotFound:         return "Элемент не найден в Keychain"
        case .unhandledError(let s): return "Keychain ошибка: \(s)"
        }
    }
}

// MARK: - Менеджер

final class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    private let service = Bundle.main.bundleIdentifier ?? "com.vreader.app"

    // MARK: Сохранить

    func save(_ value: String, for key: String, synchronizable: Bool = true) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.unexpectedData }

        // Удаляем старое, чтобы не получить errSecDuplicateItem
        _ = try? delete(key: key)

        var query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     key,
            kSecValueData as String:       data,
            kSecAttrAccessible as String:  kSecAttrAccessibleWhenUnlocked
        ]

        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }

    // MARK: Прочитать

    func read(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      key,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny // ищем и sync и local
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { throw KeychainError.itemNotFound }
        guard status == errSecSuccess   else { throw KeychainError.unhandledError(status: status) }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return string
    }

    // MARK: Удалить

    @discardableResult
    func delete(key: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String:              kSecClassGenericPassword,
            kSecAttrService as String:        service,
            kSecAttrAccount as String:        key,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound { return false }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        return true
    }

    // MARK: Проверить существование

    func exists(key: String) -> Bool {
        (try? read(key: key)) != nil
    }
}
