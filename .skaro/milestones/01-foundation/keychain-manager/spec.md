# Specification: keychain-manager

## Context
Инвариант #3 требует что все credentials хранятся только в Keychain. Gemini API ключ, OAuth токены, WebDAV пароли — только KeychainManager. Существующий KeychainManager.swift нужно проверить и дополнить до полной реализации.

## User Scenarios
1. **Пользователь вводит WebDAV пароль:** Сохраняется в Keychain, никогда не попадает в UserDefaults или логи.
2. **GeminiService запрашивает API ключ:** Получает из KeychainManager.shared, не из кода или Info.plist.
3. **OAuth токен истекает:** OAuthManager обновляет токен и сохраняет новый в Keychain.

## Functional Requirements
- FR-01: KeychainManager — singleton (shared), @MainActor или actor для thread safety
- FR-02: func save(key: String, value: String) throws — сохранение строки
- FR-03: func load(key: String) throws -> String — загрузка строки
- FR-04: func delete(key: String) throws — удаление
- FR-05: func save(key: String, data: Data) throws — сохранение Data (для токенов)
- FR-06: func load(key: String) throws -> Data — загрузка Data
- FR-07: Определить enum KeychainKey с предопределёнными ключами: geminiAPIKey, googleDriveAccessToken, googleDriveRefreshToken, dropboxAccessToken, dropboxRefreshToken, oneDriveAccessToken, oneDriveRefreshToken, webDAVPassword(host: String), smbPassword(host: String)
- FR-08: Использовать kSecClassGenericPassword с kSecAttrService = bundle identifier
- FR-09: Ошибки через VReaderError с ErrorCode.authentication
- FR-10: func exists(key: String) -> Bool — проверка наличия без загрузки значения
- FR-11: Никаких значений credentials в логах — DiagnosticsService не должен получать доступ к значениям

## Non-Functional Requirements
- NFR-01: Thread-safe доступ (actor или @MainActor)
- NFR-02: Использовать kSecAttrAccessibleAfterFirstUnlock для работы в фоне
- NFR-03: Поддержка App Group keychain для Widget extension если необходимо

## Boundaries (что НЕ входит)
- Не реализовывать биометрическую аутентификацию
- Не хранить в Keychain данные, не являющиеся credentials (книги, настройки)
- Не реализовывать миграцию из UserDefaults в Keychain

## Acceptance Criteria
- [ ] KeychainManager.shared существует и компилируется
- [ ] Все CRUD операции реализованы (save, load, delete, exists)
- [ ] KeychainKey enum содержит все предопределённые ключи
- [ ] Ошибки типизированы через VReaderError
- [ ] Thread-safe реализация
- [ ] Тест: сохранить строку, загрузить, удалить — без ошибок
- [ ] Нет логирования значений credentials

## Open Questions
- Нужна ли поддержка iCloud Keychain синхронизации (kSecAttrSynchronizable)?
- Как обрабатывать случай когда пользователь удаляет приложение и переустанавливает — очищать Keychain или сохранять?