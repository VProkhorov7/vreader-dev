# Specification: icloud-settings-store

## Context
Архитектура требует хранения настроек в `iCloudSettingsStore` и кэширования `isPremium` с TTL 24 часа. `NSUbiquitousKeyValueStore` требует entitlement `com.apple.developer.ubiquity-kvs-identifier`. Существующий `iCLoudSettingsStore.swift` (опечатка в имени) требует исправления и расширения.

## User Scenarios
1. **Пользователь меняет тему на iPhone:** Тема автоматически применяется на iPad через iCloud.
2. **Устройство offline:** isPremium кэш используется для разблокировки Premium функций (TTL 24ч).
3. **TTL кэша истёк и нет сети:** Приложение деградирует до Free tier с понятным сообщением.

## Functional Requirements
- FR-01: `iCloudSettingsStore` — `@Observable` `final class`, singleton `iCloudSettingsStore.shared`, isolated to `@MainActor` throughout. Eagerly initialized in `VreaderApp.init()` on `MainActor`.
- FR-02: Defines `iCloudSettingsStoreProtocol` exposing all typed properties (`currentThemeID`, `defaultFontSize`, `lineSpacing`, `isAutoScrollEnabled`), `isPremiumCache: Bool`, `isPremiumCacheValid: Bool`, and `setCachedPremium(_ value: Bool)`. `iCloudSettingsStore` conforms to this protocol.
- FR-03: Uses `NSUbiquitousKeyValueStore.default` for synchronization.
- FR-04: **iCloud-synced settings** (stored in `NSUbiquitousKeyValueStore`): `currentThemeID: String`, `defaultFontSize: Double`, `lineSpacing: Double`, `isPremiumCache` (key `"isPremiumCache"`, Bool) and `isPremiumCacheTimestamp` (key `"isPremiumCacheTimestamp"`, Double / `TimeInterval` since 1970).
- FR-05: **Local-only settings** (stored in `UserDefaults`): `isAutoScrollEnabled: Bool` and any future device-specific preferences. These are never written to `NSUbiquitousKeyValueStore`.
- FR-06: `isPremiumCacheValid: Bool` — returns `true` if the stored timestamp is no older than 24 hours from `Date.now`.
- FR-07: `setCachedPremium(_ value: Bool)` — writes `"isPremiumCache"` and `"isPremiumCacheTimestamp"` (current `Date.now.timeIntervalSince1970`) to `NSUbiquitousKeyValueStore`. This method is the only write path for the premium cache.
- FR-08: Subscribes to `NSUbiquitousKeyValueStore.didChangeExternallyNotification`. Handler updates only the four iCloud-synced typed settings (`currentThemeID`, `defaultFontSize`, `lineSpacing`). **`isPremiumCache` and `isPremiumCacheTimestamp` keys are explicitly ignored** in this handler — remote premium cache values are never accepted.
- FR-09: **Graceful degradation when `NSUbiquitousKeyValueStore` is unavailable** (missing entitlement): `currentThemeID`, `defaultFontSize`, and `lineSpacing` fall back to `UserDefaults`; `isPremiumCache` is silently dropped — `isPremiumCache` returns `false` and `isPremiumCacheValid` always returns `false`.
- FR-10: `isPremium` is **never** a source of truth — `isPremiumCache` is explicitly a cache only. This is documented via a protocol-level comment on `iCloudSettingsStoreProtocol`.

## Non-Functional Requirements
- NFR-01: Write to KVStore < 5ms.
- NFR-02: Total stored data < 1MB (hard limit of `NSUbiquitousKeyValueStore`).
- NFR-03: `iCloudSettingsStore` is `@MainActor`-isolated; all property access and mutation must occur on the main actor.

## Boundaries (что НЕ входит)
- Do not store credentials — Keychain only.
- Do not synchronize `isPremium` through CloudKit — prohibited by architectural invariant.
- Do not implement `PremiumStateValidator` — separate task.
- Do not accept remote `isPremiumCache` values from `didChangeExternallyNotification`.

## Acceptance Criteria
- [ ] Typo in filename corrected: file is named `iCloudSettingsStore.swift`.
- [ ] `iCloudSettingsStoreProtocol` is defined with all typed properties, `isPremiumCacheValid`, and `setCachedPremium(_:)`; `iCloudSettingsStore` conforms to it.
- [ ] `iCloudSettingsStore.shared` is eagerly initialized in `VreaderApp.init()` on `@MainActor`.
- [ ] `currentThemeID`, `defaultFontSize`, `lineSpacing` sync between devices via `NSUbiquitousKeyValueStore`.
- [ ] `isAutoScrollEnabled` is stored in `UserDefaults` only and never written to `NSUbiquitousKeyValueStore`.
- [ ] `isPremiumCache` uses two separate KVStore keys: `"isPremiumCache"` (Bool) and `"isPremiumCacheTimestamp"` (Double).
- [ ] `isPremiumCacheValid` returns `false` when timestamp is older than 24 hours.
- [ ] `setCachedPremium(_:)` writes both keys atomically in the same call.
- [ ] `didChangeExternallyNotification` handler ignores `"isPremiumCache"` and `"isPremiumCacheTimestamp"` keys entirely.
- [ ] When `NSUbiquitousKeyValueStore` is unavailable: `currentThemeID`, `defaultFontSize`, `lineSpacing` fall back to `UserDefaults`; `isPremiumCache` returns `false`; `isPremiumCacheValid` returns `false`.
- [ ] No credentials in any storage path.
- [ ] All `@MainActor` isolation requirements are met — no cross-actor access without `await`.

## Open Questions
*All questions resolved via Q&A. No open questions remain.*