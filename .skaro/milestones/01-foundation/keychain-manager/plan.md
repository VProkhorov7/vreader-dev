## plan.md

## Stage 1: Core KeychainManager Implementation + Unit Tests

**Goal:** Deliver the complete, production-ready `KeychainManager` actor with all CRUD operations, `KeychainKey` enum (including host-scoped keys), iCloud Keychain opt-in per key, first-launch cleanup, `deleteAll()`, and a full unit test suite covering all acceptance criteria.

**Depends on:** None (existing `KeychainManager.swift` and `ErrorCode.swift` are inputs to be replaced/extended)

**Inputs:**
- `App/Vreader/Vreader/KeychainManager.swift` — existing stub to replace
- `Vreader/KeychainManager.swift` — existing stub to replace
- `Vreader/ErrorCode.swift` — existing `ErrorCode` enum (must add `.authentication` if absent)
- `App/Vreader/Vreader/AppError.swift` — existing `VReaderError` definition
- `Vreader/AppError.swift` — existing `VReaderError` definition
- Specification: keychain-manager (FR-01 through FR-13, NFR-01 through NFR-03)
- Architecture document (Security Invariants, Architectural Invariants #3)

**Outputs:**
- `App/Vreader/Vreader/KeychainManager.swift` — full replacement
- `Vreader/KeychainManager.swift` — full replacement (canonical source)
- `Vreader/ErrorCode.swift` — add `.authentication` case if missing
- `App/Vreader/Vreader/AppError.swift` — ensure `VReaderError` wraps `ErrorCode.authentication`
- `App/Vreader/VreaderTests/KeychainManagerTests.swift` — new unit test file
- `VreaderTests/KeychainManagerTests.swift` — new unit test file
- `AI_NOTES.md` — stage notes

**DoD:**
- [ ] `KeychainManager` is declared as `actor` (not class, not struct)
- [ ] `KeychainManager.shared` singleton exists and compiles
- [ ] `save(key:value:)` implements upsert: `SecItemAdd` → on `errSecDuplicateItem` → `SecItemUpdate`; no error thrown on duplicate
- [ ] `load(key:) -> String?` returns `nil` for missing key, throws only for genuine OS errors
- [ ] `save(key:data:)` implements upsert with same semantics
- [ ] `load(key:) -> Data?` returns `nil` for missing key, throws only for genuine OS errors
- [ ] `delete(key:)` implemented; `errSecItemNotFound` treated as no-op (not thrown)
- [ ] `exists(key:) -> Bool` implemented; never throws
- [ ] `deleteAll()` removes all Keychain items owned by the app
- [ ] `KeychainKey` enum contains all 11 predefined keys from FR-07
- [ ] `webDAVPassword(host:)` uses `kSecAttrAccount = host`, `kSecAttrService = bundleID + ".webdav"` — no string interpolation as primary key
- [ ] `smbPassword(host:)` uses `kSecAttrAccount = host`, `kSecAttrService = bundleID + ".smb"`
- [ ] `KeychainKey.isSynchronizable` computed property: OAuth tokens return `true`, all others return `false`
- [ ] `kSecAttrSynchronizable` set correctly on every `SecItem*` call
- [ ] `kSecAttrAccessibleAfterFirstUnlock` set on all items (NFR-02)
- [ ] First-launch cleanup: `UserDefaults` sentinel `"keychainDidInitialize"` checked on `init`; if absent, `deleteAll()` called, then sentinel set
- [ ] `kSecAttrService = Bundle.main.bundleIdentifier` for standard keys
- [ ] Errors thrown as `VReaderError` with `ErrorCode.authentication`
- [ ] No credential values in logs — only key names and `OSStatus` codes logged
- [ ] Unit test: save string → load → assert equal → delete → load returns `nil`
- [ ] Unit test: save twice same key → no error (upsert)
- [ ] Unit test: clear sentinel → init → existing items wiped
- [ ] Unit test: `webDAVPassword(host: "a.example.com")` and `webDAVPassword(host: "b.example.com")` stored and retrieved independently without collision
- [ ] All callers in existing codebase (`WebDAVProvider.swift`, `iCloudProvider.swift`) use `await` — no synchronous access
- [ ] `AI_NOTES.md` written

**Risks:**
- `VReaderError` / `ErrorCode` may not yet have `.authentication` — must add without breaking existing cases
- Existing `KeychainManager.swift` may have callers that use synchronous API — must audit `WebDAVProvider.swift`, `iCloudProvider.swift`, `VreaderApp.swift` and update call sites to `await`
- Unit tests for Keychain require a real device or simulator with Keychain entitlement; tests must be written to skip gracefully in CI environments without entitlements
- Two parallel directory trees (`App/Vreader/Vreader/` and `Vreader/`) must both be updated consistently

---

## Verify

```yaml
## Verify
- name: Swift build (App target)
  command: xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20

- name: Unit tests (KeychainManager)
  command: xcodebuild test -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VreaderTests/KeychainManagerTests 2>&1 | tail -30

- name: Check no force-unwrap in KeychainManager
  command: grep -n "!\." App/Vreader/Vreader/KeychainManager.swift || echo "OK - no force unwrap"

- name: Check actor declaration
  command: grep -n "^actor KeychainManager" App/Vreader/Vreader/KeychainManager.swift

- name: Check no credential values in logs
  command: grep -n "DiagnosticsService\|os_log\|Logger" App/Vreader/Vreader/KeychainManager.swift | grep -v "key\|status\|OSStatus" || echo "OK"

- name: Check kSecAttrAccessibleAfterFirstUnlock present
  command: grep -c "kSecAttrAccessibleAfterFirstUnlock" App/Vreader/Vreader/KeychainManager.swift

- name: Check isSynchronizable property exists
  command: grep -n "isSynchronizable" App/Vreader/Vreader/KeychainManager.swift

- name: Check sentinel flag usage
  command: grep -n "keychainDidInitialize" App/Vreader/Vreader/KeychainManager.swift
```