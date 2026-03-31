# Specification: keychain-manager

## Context
Инвариант #3 требует что все credentials хранятся только в Keychain. Gemini API ключ, OAuth токены, WebDAV пароли — только KeychainManager. Существующий KeychainManager.swift нужно проверить и дополнить до полной реализации.

## User Scenarios
1. **Пользователь вводит WebDAV пароль:** Сохраняется в Keychain, никогда не попадает в UserDefaults или логи.
2. **GeminiService запрашивает API ключ:** Получает из KeychainManager.shared, не из кода или Info.plist.
3. **OAuth токен истекает:** OAuthManager обновляет токен и сохраняет новый в Keychain.

## Functional Requirements
- FR-01: KeychainManager — singleton (`shared`), implemented as a Swift `actor` — all callers use `await`, fully thread-safe, works on any thread
- FR-02: `func save(key: String, value: String) throws` — сохранение строки; upsert semantics: attempt `SecItemAdd`, on `errSecDuplicateItem` automatically call `SecItemUpdate` (silent overwrite, no error thrown)
- FR-03: `func load(key: String) -> String?` — загрузка строки; returns `nil` when key is not found (missing key is not an error); throws only for actual Keychain system errors
- FR-04: `func delete(key: String) throws` — удаление
- FR-05: `func save(key: String, data: Data) throws` — сохранение Data (для токенов); same upsert semantics as FR-02
- FR-06: `func load(key: String) -> Data?` — загрузка Data; returns `nil` when key is not found; throws only for actual Keychain system errors
- FR-07: Определить `enum KeychainKey` с предопределёнными ключами:
  - `geminiAPIKey` — not synchronizable
  - `googleDriveAccessToken` — synchronizable (iCloud Keychain opt-in)
  - `googleDriveRefreshToken` — synchronizable
  - `dropboxAccessToken` — synchronizable
  - `dropboxRefreshToken` — synchronizable
  - `oneDriveAccessToken` — synchronizable
  - `oneDriveRefreshToken` — synchronizable
  - `webDAVPassword(host: String)` — **not** synchronizable (security-sensitive); stored as `kSecAttrAccount = host`, `kSecAttrService = bundleID + ".webdav"`; separate Keychain item per host; no string interpolation used as the primary key
  - `smbPassword(host: String)` — **not** synchronizable (security-sensitive); stored as `kSecAttrAccount = host`, `kSecAttrService = bundleID + ".smb"`; separate Keychain item per host
- FR-08: Use `kSecClassGenericPassword` with `kSecAttrService = bundle identifier` for standard keys; host-scoped keys use service suffix as described in FR-07
- FR-09: Errors typed via `VReaderError` with `ErrorCode.authentication`; missing-key case returns `nil` (not an error); only genuine Keychain OS errors (non-`errSecSuccess`, non-`errSecItemNotFound`) are thrown
- FR-10: `func exists(key: String) -> Bool` — проверка наличия без загрузки значения; returns `false` for missing key, never throws
- FR-11: Никаких значений credentials в логах — `DiagnosticsService` не должен получать доступ к значениям; log only key names and OSStatus codes, never values
- FR-12: **iCloud Keychain synchronization opt-in per key** — `KeychainKey` exposes a computed property `isSynchronizable: Bool`; OAuth tokens (`googleDrive*`, `dropbox*`, `oneDrive*`) return `true`; all other keys return `false`; `kSecAttrSynchronizable` is set accordingly on every `SecItem*` call
- FR-13: **First-launch-after-reinstall cleanup** — on first launch after a fresh install, detect via a `UserDefaults` sentinel flag (`"keychainDidInitialize"`); if flag is absent, call `deleteAll()` to wipe all Keychain items owned by the app, then set the flag; this ensures stale credentials from a previous install do not persist

## Non-Functional Requirements
- NFR-01: Thread-safe access via Swift `actor` — no `@MainActor`, no locks, no DispatchQueue wrappers needed
- NFR-02: Use `kSecAttrAccessibleAfterFirstUnlock` for all items to support background operation (e.g., background sync, widget)
- NFR-03: App Group Keychain support for Widget extension — if an App Group identifier is configured, use `kSecAttrAccessGroup` so the widget can read the same Keychain items (opt-in, not required for base implementation)

## Boundaries (что НЕ входит)
- Не реализовывать биометрическую аутентификацию
- Не хранить в Keychain данные, не являющиеся credentials (книги, настройки)
- Не реализовывать миграцию из UserDefaults в Keychain

## Acceptance Criteria
- [ ] `KeychainManager.shared` exists, compiles, and is declared as a Swift `actor`
- [ ] All callers use `await` — no synchronous access to `KeychainManager` anywhere in the codebase
- [ ] All CRUD operations implemented: `save(_:value:)`, `load(_:) -> String?`, `save(_:data:)`, `load(_:) -> Data?`, `delete(_:)`, `exists(_:)`
- [ ] `save()` performs upsert: calling `save()` twice for the same key does not throw `errSecDuplicateItem`
- [ ] `load()` returns `nil` for a missing key and does not throw
- [ ] `KeychainKey` enum contains all predefined keys listed in FR-07
- [ ] `webDAVPassword(host:)` and `smbPassword(host:)` use `kSecAttrAccount = host` and a service-suffix strategy — no string interpolation as primary key
- [ ] OAuth token keys have `isSynchronizable == true`; `webDAVPassword`, `smbPassword`, `geminiAPIKey` have `isSynchronizable == false`
- [ ] `kSecAttrSynchronizable` is set correctly on every `SecItem*` call based on `KeychainKey.isSynchronizable`
- [ ] Errors are typed via `VReaderError` with `ErrorCode.authentication`; only genuine OS errors are thrown
- [ ] `exists()` returns `Bool`, never throws
- [ ] No credential values appear in logs — only key names and `OSStatus` codes are logged
- [ ] First-launch-after-reinstall: stale Keychain items are deleted when `UserDefaults` sentinel is absent; sentinel is set after cleanup
- [ ] `deleteAll()` function exists and removes all Keychain items owned by the app
- [ ] Unit test: save a string → load → assert equal → delete → load returns `nil`
- [ ] Unit test: save twice for same key → no error thrown (upsert)
- [ ] Unit test: simulate reinstall (clear UserDefaults sentinel) → `KeychainManager` init wipes existing items
- [ ] Unit test: `webDAVPassword(host: "a.example.com")` and `webDAVPassword(host: "b.example.com")` stored and retrieved independently without collision

## Open Questions
~~- Нужна ли поддержка iCloud Keychain синхронизации (kSecAttrSynchronizable)?~~
Resolved: Opt-in per key — OAuth tokens sync (`isSynchronizable = true`), WebDAV/SMB passwords and `geminiAPIKey` do not (`isSynchronizable = false`). See FR-12.

~~- Как обрабатывать случай когда пользователь удаляет приложение и переустанавливает — очищать Keychain или сохранять?~~
Resolved: Clear all Keychain items on first launch after reinstall via `UserDefaults` sentinel flag. See FR-13.