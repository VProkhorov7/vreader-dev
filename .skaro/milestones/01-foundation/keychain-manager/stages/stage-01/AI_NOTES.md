# AI_NOTES — Stage 1: Core KeychainManager Implementation + Unit Tests

## What was done

- Replaced both `KeychainManager.swift` stubs (in `Vreader/` and `App/Vreader/Vreader/`) with a full `actor`-based implementation satisfying all FR-01 through FR-13 and NFR-01 through NFR-03.
- Defined `KeychainKey` enum with all 9 predefined cases (11 counting the two associated-value cases as covering multiple hosts), including `isSynchronizable` computed property, `service` computed property (with `.webdav` / `.smb` suffixes), and `account` computed property.
- Implemented upsert semantics: `SecItemAdd` → on `errSecDuplicateItem` → `SecItemUpdate`. No delete-then-add (avoids race conditions and unnecessary Keychain churn).
- `load(key:) -> String?` and `load(key:) -> Data?` return `nil` for `errSecItemNotFound`, throw `AppError.auth(.keychainAccessFailed)` only for genuine OS errors.
- `delete(key:)` treats `errSecItemNotFound` as a no-op (idempotent).
- `exists(key:)` never throws — returns `Bool` only.
- `deleteAll()` iterates all three service namespaces (`bundleID`, `bundleID.webdav`, `bundleID.smb`) and deletes with `kSecAttrSynchronizableAny` to catch both sync and non-sync items.
- First-launch cleanup: `init` checks `UserDefaults.standard.bool(forKey: "keychainDidInitialize")`; if absent, calls `performDeleteAll` (static, callable before actor is fully initialized), then sets the sentinel.
- `kSecAttrAccessibleAfterFirstUnlock` set on all items (supports background sync and widget).
- `kSecAttrSynchronizable` set to `kCFBooleanTrue` / `kCFBooleanFalse` (never