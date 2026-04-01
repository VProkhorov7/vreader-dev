## plan.md

## Stage 1: Core Implementation — iCloudSettingsStore

**Goal:** Deliver the complete, production-ready `iCloudSettingsStore` module: protocol definition, concrete `@Observable @MainActor` singleton, graceful fallback logic, TTL-based premium cache, and `didChangeExternallyNotification` handler that ignores premium keys. Update `VreaderApp.swift` for eager initialization. Add unit tests covering all acceptance criteria.

**Depends on:** none (replaces existing `Vreader/iCLoudSettingsStore.swift`)

**Inputs:**
- `Vreader/iCLoudSettingsStore.swift` (existing file with typo — to be replaced)
- `Vreader/VreaderApp.swift` (needs eager init call)
- `App/Vreader/Vreader/VreaderApp.swift` (App copy — same update)
- `App/Vreader/Vreader/iCloudSettingsStore.swift` (App copy — to be replaced/created)
- Specification, Clarifications, Architecture document
- `VreaderTests/VreaderTests.swift` (existing test file)

**Outputs:**
- `Vreader/iCloudSettingsStore.swift` ← **new file, correct name** (replaces `iCLoudSettingsStore.swift`)
- `App/Vreader/Vreader/iCloudSettingsStore.swift` ← **new file, correct name** (replaces existing)
- `Vreader/VreaderApp.swift` ← modified (eager init on `@MainActor`)
- `App/Vreader/Vreader/VreaderApp.swift` ← modified (eager init on `@MainActor`)
- `VreaderTests/iCloudSettingsStoreTests.swift` ← **new test file**

**DoD:**
- [ ] Old file `Vreader/iCLoudSettingsStore.swift` is deleted (or emptied and replaced by the new correctly-named file)
- [ ] `iCloudSettingsStoreProtocol` is defined with: `currentThemeID: String`, `defaultFontSize: Double`, `lineSpacing: Double`, `isAutoScrollEnabled: Bool`, `isPremiumCache: Bool`, `isPremiumCacheValid: Bool`, `setCachedPremium(_ value: Bool)`
- [ ] Protocol carries a doc-comment stating `isPremiumCache` is a cache only, never a source of truth
- [ ] `iCloudSettingsStore` is `@Observable`, `final class`, `@MainActor`, conforms to `iCloudSettingsStoreProtocol`
- [ ] `iCloudSettingsStore.shared` is a `static let` singleton
- [ ] `currentThemeID`, `defaultFontSize`, `lineSpacing` read/write `NSUbiquitousKeyValueStore.default`
- [ ] `isAutoScrollEnabled` reads/writes `UserDefaults.standard` only — never touches `NSUbiquitousKeyValueStore`
- [ ] `isPremiumCache` reads from `NSUbiquitousKeyValueStore` key `"isPremiumCache"` (Bool)
- [ ] `isPremiumCacheTimestamp` reads from `NSUbiquitousKeyValueStore` key `"isPremiumCacheTimestamp"` (Double)
- [ ] `isPremiumCacheValid` returns `true` only when `Date.now.timeIntervalSince1970 - timestamp < 86400`
- [ ] `setCachedPremium(_:)` writes both `"isPremiumCache"` and `"isPremiumCacheTimestamp"` in the same call
- [ ] `didChangeExternallyNotification` handler updates `currentThemeID`, `defaultFontSize`, `lineSpacing` from remote; explicitly skips `"isPremiumCache"` and `"isPremiumCacheTimestamp"` keys
- [ ] Graceful degradation: when `NSUbiquitousKeyValueStore` is unavailable, `currentThemeID`/`defaultFontSize`/`lineSpacing` fall back to `UserDefaults`; `isPremiumCache` returns `false`; `isPremiumCacheValid` returns `false`
- [ ] `VreaderApp.init()` eagerly initializes `iCloudSettingsStore.shared` on `@MainActor`
- [ ] No credentials stored anywhere in this file
- [ ] All UI strings (if any) go through `L10n.*`
- [ ] No force-unwraps
- [ ] Unit tests cover: TTL valid/expired, `setCachedPremium`, external notification ignores premium keys, `isAutoScrollEnabled` isolation, fallback mode

**Risks:**
- `NSUbiquitousKeyValueStore` cannot be instantiated in unit tests without entitlement — tests must use a protocol-based mock or dependency injection via the protocol. The concrete singleton uses `NSUbiquitousKeyValueStore.default`; tests inject a mock conforming to `iCloudSettingsStoreProtocol`.
- The old file `iCLoudSettingsStore.swift` must be explicitly removed from the Xcode project reference in `project.pbxproj` to avoid duplicate symbol errors — flag this as a manual step in `AI_NOTES.md`.
- Swift 6 strict concurrency: all `@MainActor` isolation must be consistent; `NotificationCenter` observer must dispatch to `MainActor` explicitly.

---

## Verify

```yaml
## Verify
- name: Build check (Vreader target)
  command: xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20

- name: Unit tests (iCloudSettingsStore)
  command: xcodebuild test -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VreaderTests/iCloudSettingsStoreTests 2>&1 | tail -30

- name: Check old typo file is gone
  command: test ! -f Vreader/iCLoudSettingsStore.swift && echo "OK: old file removed" || echo "FAIL: old file still exists"

- name: Check new file exists (root target)
  command: test -f Vreader/iCloudSettingsStore.swift && echo "OK" || echo "FAIL"

- name: Check new file exists (App target)
  command: test -f App/Vreader/Vreader/iCloudSettingsStore.swift && echo "OK" || echo "FAIL"

- name: Verify no NSUbiquitousKeyValueStore write for isAutoScrollEnabled
  command: grep -n "isAutoScrollEnabled" Vreader/iCloudSettingsStore.swift | grep -v "UserDefaults" | grep "ubiquitous\|KVStore\|NSUbiquitous" && echo "FAIL: isAutoScrollEnabled written to KVStore" || echo "OK: isAutoScrollEnabled not in KVStore"

- name: Verify isPremiumCache key ignored in notification handler
  command: grep -A 30 "didChangeExternally" Vreader/iCloudSettingsStore.swift | grep -c "isPremiumCache" | xargs -I{} sh -c 'test {} -ge 1 && echo "OK: key referenced in handler (for ignore logic)" || echo "WARN: key not mentioned"'

- name: Verify no credentials in store file
  command: grep -iE "password|token|secret|apiKey|api_key" Vreader/iCloudSettingsStore.swift && echo "FAIL: credentials found" || echo "OK: no credentials"
```