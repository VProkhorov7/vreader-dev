# Tasks: icloud-settings-store

## Stage 1: Core Implementation — iCloudSettingsStore

- [ ] Delete (or empty) old typo file `Vreader/iCLoudSettingsStore.swift` and note manual Xcode project reference removal in `AI_NOTES.md` → `Vreader/iCLoudSettingsStore.swift` (removed)
- [ ] Define `iCloudSettingsStoreProtocol` with all typed properties (`currentThemeID`, `defaultFontSize`, `lineSpacing`, `isAutoScrollEnabled`), `isPremiumCache: Bool`, `isPremiumCacheValid: Bool`, `setCachedPremium(_ value: Bool)`, and protocol-level doc-comment marking `isPremiumCache` as cache-only → `Vreader/iCloudSettingsStore.swift`
- [ ] Implement `iCloudSettingsStore`: `@Observable final class`, `@MainActor`, `static let shared`, conforming to `iCloudSettingsStoreProtocol` → `Vreader/iCloudSettingsStore.swift`
- [ ] Implement iCloud-synced properties (`currentThemeID`, `defaultFontSize`, `lineSpacing`) reading/writing `NSUbiquitousKeyValueStore.default` with `UserDefaults` fallback when KVStore unavailable → `Vreader/iCloudSettingsStore.swift`
- [ ] Implement local-only property `isAutoScrollEnabled` reading/writing `UserDefaults.standard` exclusively, never touching `NSUbiquitousKeyValueStore` → `Vreader/iCloudSettingsStore.swift`
- [ ] Implement `isPremiumCache` (key `"isPremiumCache"`) and `isPremiumCacheTimestamp` (key `"isPremiumCacheTimestamp"`) backed by `NSUbiquitousKeyValueStore` → `Vreader/iCloudSettingsStore.swift`
- [ ] Implement `isPremiumCacheValid` returning `true` only when stored timestamp is within 24 hours of `Date.now` → `Vreader/iCloudSettingsStore.swift`
- [ ] Implement `setCachedPremium(_ value: Bool)` writing both KVStore keys atomically in one call → `Vreader/iCloudSettingsStore.swift`
- [ ] Implement graceful degradation: detect KVStore unavailability, fall back to `UserDefaults` for settings, return `false`/`false` for `isPremiumCache`/`isPremiumCacheValid` → `Vreader/iCloudSettingsStore.swift`
- [ ] Subscribe to `NSUbiquitousKeyValueStore.didChangeExternallyNotification`; handler updates only `currentThemeID`, `defaultFontSize`, `lineSpacing`; explicitly ignores `"isPremiumCache"` and `"isPremiumCacheTimestamp"` keys → `Vreader/iCloudSettingsStore.swift`
- [ ] Ensure all `NotificationCenter` observer callbacks dispatch to `@MainActor` (Swift 6 concurrency compliance) → `Vreader/iCloudSettingsStore.swift`
- [ ] Mirror identical implementation to App target → `App/Vreader/Vreader/iCloudSettingsStore.swift`
- [ ] Update `VreaderApp.init()` to eagerly initialize `iCloudSettingsStore.shared` on `@MainActor` → `Vreader/VreaderApp.swift`
- [ ] Update App target `VreaderApp.init()` with same eager initialization → `App/Vreader/Vreader/VreaderApp.swift`
- [ ] Write unit tests: TTL valid (timestamp < 24h ago → `isPremiumCacheValid == true`) → `VreaderTests/iCloudSettingsStoreTests.swift`
- [ ] Write unit tests: TTL expired (timestamp > 24h ago → `isPremiumCacheValid == false`) → `VreaderTests/iCloudSettingsStoreTests.swift`
- [ ] Write unit tests: `setCachedPremium(true)` sets both keys; `setCachedPremium(false)` sets both keys → `VreaderTests/iCloudSettingsStoreTests.swift`
- [ ] Write unit tests: external notification with `"isPremiumCache"` key does NOT update `isPremiumCache` on the store → `VreaderTests/iCloudSettingsStoreTests.swift`
- [ ] Write unit tests: `isAutoScrollEnabled` changes do not appear in `NSUbiquitousKeyValueStore` → `VreaderTests/iCloudSettingsStoreTests.swift`
- [ ] Write unit tests: fallback mode — mock KVStore unavailable, verify settings read from `UserDefaults`, `isPremiumCache == false`, `isPremiumCacheValid == false` → `VreaderTests/iCloudSettingsStoreTests.swift`
- [ ] Write `AI_NOTES.md` documenting: manual Xcode project reference removal for old typo file, entitlement requirement, Swift 6 `@MainActor` dispatch pattern used → `AI_NOTES.md`