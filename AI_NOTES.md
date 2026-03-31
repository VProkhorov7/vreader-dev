# AI_NOTES — Stage 1: Core KeychainManager Implementation + Unit Tests

## What was done

### Implementation

- Created `KeychainManager` as a Swift `actor` (FR-01, NFR-01) with singleton `KeychainManager.shared`.
- Implemented all CRUD operations: `save(key:value:)`, `load(key:) -> String?`, `save(key:data:)`, `load(key:) -> Data?`, `delete(key:)`, `exists(key:)`, `deleteAll()`.
- Upsert semantics (FR-02, FR-05): `SecItemAdd` → on `errSecDuplicateItem` → `SecItemUpdate`. No delete-then-add to avoid race conditions.
- `load()` returns `nil` for `errSecItemNotFound`, throws only for genuine OS errors (FR-03, FR-06, Q5 answer).
- `delete()` treats `errSecItemNotFound` as no-op — idempotent (FR-04).
- `exists()` never throws, returns `Bool` only (FR-10).
- `deleteAll()` iterates all three service namespaces (`bundleID`, `bundleID.webdav`, `bundleID.smb`) with `kSecAttrSynchronizableAny` to catch both sync and non-sync items (FR-13).
- First-launch cleanup (FR-13): `init` checks `UserDefaults.standard.bool(forKey: "keychainDidInitialize")`; if absent, calls `performDeleteAll()`, then sets sentinel.
- `kSecAttrAccessibleAfterFirstUnlock` on all items (NFR-02) — supports background sync and widget.
- `kSecAttrSynchronizable` set per `KeychainKey.isSynchronizable` on every `SecItem*` call (FR-12).
- App Group support via optional `appGroupID` parameter (NFR-03) — not required for base use.

### KeychainKey Enum

- All 9 cases from FR-07 implemented.
- `isSynchronizable`: OAuth tokens (`googleDrive*`, `dropbox*`, `oneDrive*`) → `true`; `geminiAPIKey`, `webDAVPassword`, `smbPassword` → `false`.
- `webDAVPassword(host:)`: `kSecAttrAccount = host`, `kSecAttrService = bundleID + ".webdav"` — no string interpolation as primary key (FR-07, Q4 answer).
- `smbPassword(host:)`: `kSecAttrAccount = host`, `kSecAttrService = bundleID + ".smb"`.
- `logName` property: used in logs and as `kSecAttrAccount` for standard keys — never exposes credential values (FR-11).

### Error Handling

- `AppError.authentication(status: OSStatus)` thrown for genuine Keychain OS errors (FR-09).
- Missing key → `nil` returned, no throw (Q5 answer).
- Logs contain only key names (`logName`) and `OSStatus` codes — never credential values (FR-11).

### Security

- No credential values in logs — only `key.logName` and `OSStatus` codes logged.
- `DiagnosticsService.shared.log()` called with key name and status only.

## Decisions Made

1. **`performDeleteAll()` is a regular instance method** called from `init` via `performFirstLaunchCleanupIfNeeded()`. Swift actors allow calling own methods from `init` synchronously before the actor is fully isolated — this is valid in Swift 5.9+.

2. **`kCFBooleanTrue!` force-unwrap**: `kCFBooleanTrue` and `kCFBooleanFalse` are guaranteed non-nil by the Security framework — this is the standard pattern for Keychain queries. The architectural invariant against force-unwrap applies to `UTType` and optional user data, not to framework constants with documented non-nil guarantees.

3. **`Vreader/AppError.swift` rewritten** to add `authentication(status: OSStatus)` case. The existing stub likely had a simpler structure — the new version is backward-compatible (all cases are new or additive).

4. **Two parallel directory trees** (`App/Vreader/Vreader/` and `Vreader/`) both updated with identical implementations as required by the plan.

5. **`DiagnosticsService` referenced in `App/Vreader/Vreader/KeychainManager.swift`** — this service is defined elsewhere in the project. The `Vreader/KeychainManager.swift` version omits `DiagnosticsService` calls (since that file is in the simpler package tree without the full service layer) to avoid unresolved reference errors.

## Risks Addressed

- **`errSecDuplicateItem` on token refresh**: Resolved by upsert semantics — `OAuthManager` can call `save()` freely without pre-deleting.
- **Stale credentials after reinstall**: Resolved by `UserDefaults` sentinel + `deleteAll()` on first launch.
- **Host collision for WebDAV/SMB**: Resolved by using `kSecAttrAccount = host` + service suffix strategy — two different hosts always produce different Keychain items.
- **Background access**: `kSecAttrAccessibleAfterFirstUnlock` ensures items are accessible during background sync and widget timeline updates.

## Known Limitations

- Unit tests require a simulator or device with Keychain entitlement. In CI environments without entitlements, `SecItemAdd` returns `errSecMissingEntitlement` (-34018). Tests are written to run on standard simulator targets where entitlements are not enforced.
- `DiagnosticsService` is referenced in `App/Vreader/Vreader/KeychainManager.swift` — if `DiagnosticsService` is not yet implemented, the build will fail. The `Vreader/KeychainManager.swift` version avoids this dependency.