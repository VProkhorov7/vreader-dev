# Tasks: keychain-manager

## Stage 1: Core KeychainManager Implementation + Unit Tests

- [ ] Audit existing `Vreader/ErrorCode.swift` — add `authentication` case to `ErrorCode` enum if absent → `Vreader/ErrorCode.swift`
- [ ] Audit existing `App/Vreader/Vreader/AppError.swift` and `Vreader/AppError.swift` — ensure `VReaderError` can wrap `ErrorCode.authentication` → `App/Vreader/Vreader/AppError.swift`, `Vreader/AppError.swift`
- [ ] Implement `KeychainKey` enum with all 11 keys from FR-07, `isSynchronizable` computed property, and host-scoped key helpers (`kSecAttrAccount`, `kSecAttrService` suffix strategy) → `Vreader/KeychainManager.swift`
- [ ] Implement `actor KeychainManager` with `shared` singleton, first-launch sentinel logic (`deleteAll()` + `UserDefaults` flag), and internal query builder respecting `isSynchronizable` and `kSecAttrAccessibleAfterFirstUnlock` → `Vreader/KeychainManager.swift`
- [ ] Implement `save(key:value:)` with upsert semantics (`SecItemAdd` → `errSecDuplicateItem` → `SecItemUpdate`) → `Vreader/KeychainManager.swift`
- [ ] Implement `load(key:) -> String?` returning `nil` for `errSecItemNotFound`, throwing `VReaderError(.authentication)` only for genuine OS errors → `Vreader/KeychainManager.swift`
- [ ] Implement `save(key:data:)` with same upsert semantics → `Vreader/KeychainManager.swift`
- [ ] Implement `load(key:) -> Data?` with same nil-for-missing semantics → `Vreader/KeychainManager.swift`
- [ ] Implement `delete(key:)` treating `errSecItemNotFound` as no-op → `Vreader/KeychainManager.swift`
- [ ] Implement `exists(key:) -> Bool` using `SecItemCopyMatching` with `kSecReturnData = false`, never throwing → `Vreader/KeychainManager.swift`
- [ ] Implement `deleteAll()` using `SecItemDelete` with service-scoped query to remove all app-owned items → `Vreader/KeychainManager.swift`
- [ ] Add logging: key names and `OSStatus` codes only — no credential values — using `os.Logger` or `DiagnosticsService` pattern → `Vreader/KeychainManager.swift`
- [ ] Copy final implementation to `App/Vreader/Vreader/KeychainManager.swift` (keep both trees in sync) → `App/Vreader/Vreader/KeychainManager.swift`
- [ ] Audit `App/Vreader/Vreader/WebDAVProvider.swift` and `Vreader/WebDAVProvider.swift` — update all `KeychainManager` call sites to use `await` → `App/Vreader/Vreader/WebDAVProvider.swift`, `Vreader/WebDAVProvider.swift`
- [ ] Audit `App/Vreader/Vreader/iCloudProvider.swift` and `Vreader/iCloudProvider.swift` — update any `KeychainManager` call sites to use `await` → `App/Vreader/Vreader/iCloudProvider.swift`, `Vreader/iCloudProvider.swift`
- [ ] Write unit test: save string → load → assert equal → delete → load returns `nil` → `App/Vreader/VreaderTests/KeychainManagerTests.swift`
- [ ] Write unit test: save same key twice → no error thrown (upsert semantics) → `App/Vreader/VreaderTests/KeychainManagerTests.swift`
- [ ] Write unit test: clear `UserDefaults` sentinel → instantiate manager → assert existing items wiped → `App/Vreader/VreaderTests/KeychainManagerTests.swift`
- [ ] Write unit test: `webDAVPassword(host: "a.example.com")` and `webDAVPassword(host: "b.example.com")` stored and retrieved independently without collision → `App/Vreader/VreaderTests/KeychainManagerTests.swift`
- [ ] Write unit test: `geminiAPIKey.isSynchronizable == false`, `googleDriveAccessToken.isSynchronizable == true`, `webDAVPassword(host:).isSynchronizable == false` → `App/Vreader/VreaderTests/KeychainManagerTests.swift`
- [ ] Copy test file to `VreaderTests/KeychainManagerTests.swift` → `VreaderTests/KeychainManagerTests.swift`
- [ ] Write `AI_NOTES.md` documenting decisions, risks encountered, and call-site changes made → `AI_NOTES.md`