# Clarifications: icloud-settings-store

## Question 1
Should iCloudSettingsStore expose a protocol (iCloudSettingsStoreProtocol) for testability, or is a concrete singleton sufficient?

*Context:* The spec raises this as an open question; the answer determines whether unit tests can inject a mock store and whether PremiumStateValidator (a future component) can depend on an abstraction.

**Options:**
- A) Define iCloudSettingsStoreProtocol with all typed properties + setCachedPremium + isPremiumCacheValid; concrete class conforms to it; singleton is iCloudSettingsStore.shared
- B) No protocol — concrete singleton only; tests use the real store with a test NSUbiquitousKeyValueStore key prefix
- C) Protocol only for the premium-cache surface (PremiumCacheStore); settings properties stay on the concrete class

**Answer:**
Define iCloudSettingsStoreProtocol with all typed properties + setCachedPremium + isPremiumCacheValid; concrete class conforms to it; singleton is iCloudSettingsStore.shared

## Question 2
When NSUbiquitousKeyValueStore is unavailable (missing entitlement), which settings fall back to UserDefaults and which are silently dropped?

*Context:* FR-08 says 'fallback on UserDefaults for non-critical settings' but does not define which settings are critical vs non-critical, directly affecting what users lose when the entitlement is absent.

**Options:**
- A) All four typed settings (currentThemeID, defaultFontSize, lineSpacing, isAutoScrollEnabled) fall back to UserDefaults; isPremiumCache is silently dropped (returns false, cache always invalid)
- B) Only currentThemeID falls back to UserDefaults (visible UX impact); all other settings use hardcoded defaults; isPremiumCache dropped
- C) All settings including isPremiumCache fall back to UserDefaults with a clear in-memory-only flag; isPremiumCache TTL still enforced
- D) No fallback at all — throw a typed ErrorCode.sync error on init so the caller can surface the misconfiguration

**Answer:**
All four typed settings (currentThemeID, defaultFontSize, lineSpacing, isAutoScrollEnabled) fall back to UserDefaults; isPremiumCache is silently dropped (returns false, cache always invalid)

## Question 3
How should the store behave when an external iCloud change arrives (didChangeExternallyNotification) for isPremiumCache — should it accept the remote value or ignore it?

*Context:* Architectural invariant forbids isPremium sync via CloudKit, but NSUbiquitousKeyValueStore is a different channel; accepting a remotely pushed isPremiumCache=true could bypass PremiumStateValidator.

**Options:**
- A) Ignore isPremiumCache key entirely in didChangeExternallyNotification handler — only update the four typed settings
- B) Accept the remote isPremiumCache value but reset its timestamp to 'now minus 23h' so it expires within 1 hour, forcing revalidation soon
- C) Accept the remote value and timestamp as-is — the invariant only forbids CloudKit, not NSUbiquitousKeyValueStore
- D) Accept remote value only if local cache is already expired; otherwise keep local value (last-write-wins by timestamp)

**Answer:**
Ignore isPremiumCache key entirely in didChangeExternallyNotification handler — only update the four typed settings

## Question 4
What are the exact iCloud KVStore keys used for isPremiumCache — a single Bool key or two separate keys (value + timestamp)?

*Context:* The TTL mechanism requires storing both a Bool and a Date; the key naming strategy affects collision risk across app versions and testability of cache invalidation.

**Options:**
- A) Two separate keys: 'isPremiumCache' (Bool) and 'isPremiumCacheTimestamp' (Double / TimeInterval since 1970)
- B) One key storing a JSON-encoded struct {value: Bool, timestamp: Double} as a String
- C) One key storing a Dictionary [String: Any] with 'value' and 'timestamp' entries via NSUbiquitousKeyValueStore set(_:forKey:)

**Answer:**
Two separate keys: 'isPremiumCache' (Bool) and 'isPremiumCacheTimestamp' (Double / TimeInterval since 1970)

## Question 5
Should iCloudSettingsStore.shared be initialized at app launch (eager) or on first access (lazy), and on which actor/thread?

*Context:* NSUbiquitousKeyValueStore.synchronize() and NotificationCenter subscription must happen before any read; the choice of actor affects Swift 6 concurrency compliance and potential data races.

**Options:**
- A) Lazy singleton on @MainActor; synchronize() called inside init; notification observer dispatches updates to MainActor
- B) Eager initialization in VreaderApp.init() on MainActor; store is @MainActor-isolated throughout
- C) Nonisolated lazy singleton; all property access is nonisolated with internal OSAllocatedUnfairLock for thread safety; no actor annotation

**Answer:**
Eager initialization in VreaderApp.init() on MainActor; store is @MainActor-isolated throughout

## Question 6
Which settings should be synced via iCloud KVStore vs stored only locally (UserDefaults), given the 1 MB total limit?

*Context:* NFR-02 caps total KVStore usage at 1 MB; syncing all settings by default may conflict with future additions, and some settings (e.g., isAutoScrollEnabled) may be device-specific preferences.

**Options:**
- A) Sync via iCloud: currentThemeID, defaultFontSize, lineSpacing, isPremiumCache+timestamp. Local only (UserDefaults): isAutoScrollEnabled and any future device-specific prefs
- B) Sync all four typed settings + isPremiumCache via iCloud; document the ~200 byte budget per key and reserve 900 bytes for future keys
- C) Sync only currentThemeID via iCloud (highest cross-device value); all other settings are local UserDefaults only

**Answer:**
Sync via iCloud: currentThemeID, defaultFontSize, lineSpacing, isPremiumCache+timestamp. Local only (UserDefaults): isAutoScrollEnabled and any future device-specific prefs
