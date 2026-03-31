# Clarifications: keychain-manager

## Question 1
Should KeychainManager be implemented as a Swift actor or @MainActor class?

*Context:* FR-01 says 'actor or @MainActor' but the choice affects call sites: actor requires await everywhere (GeminiService, OAuthManager, WebDAVProvider), while @MainActor blocks background threads and conflicts with NFR-01 background use (kSecAttrAccessibleAfterFirstUnlock implies background access).

**Options:**
- A) Swift actor — all callers use await, fully thread-safe, works on any thread
- B) @MainActor class — simpler call sites in SwiftUI but requires Task { } in background contexts
- C) Plain class with internal DispatchQueue serialization — no await required, compatible with sync call sites

**Answer:**
Swift actor — all callers use await, fully thread-safe, works on any thread

## Question 2
Should KeychainManager support iCloud Keychain synchronization (kSecAttrSynchronizable = true)?

*Context:* The spec lists this as an open question; the answer directly affects OAuth token and WebDAV password availability when user installs the app on a second device — without sync, users must re-enter all credentials on every device.

**Options:**
- A) Yes, kSecAttrSynchronizable = true for all credential types — tokens and passwords available on all devices automatically
- B) Opt-in per key — OAuth tokens sync, WebDAV/SMB passwords do not (security-sensitive)
- C) No synchronization — kSecAttrSynchronizable = false everywhere, credentials are device-local only

**Answer:**
Opt-in per key — OAuth tokens sync, WebDAV/SMB passwords do not (security-sensitive)

## Question 3
What is the correct behavior when save() is called for a key that already exists in Keychain?

*Context:* SecItemAdd returns errSecDuplicateItem if the key exists; without an explicit update strategy the save() call will throw an error on every token refresh in OAuthManager, breaking FR-03 and the OAuth token update user scenario.

**Options:**
- A) Upsert — attempt SecItemAdd, on errSecDuplicateItem automatically call SecItemUpdate (silent overwrite)
- B) Throw a typed error (ErrorCode.authentication) and require caller to delete first
- C) Overwrite silently — always call SecItemDelete then SecItemAdd

**Answer:**
Upsert — attempt SecItemAdd, on errSecDuplicateItem automatically call SecItemUpdate (silent overwrite)

## Question 4
How should webDAVPassword(host:) and smbPassword(host:) be stored as Keychain keys when host is a runtime value?

*Context:* KeychainKey is an enum (FR-07) but associated-value cases cannot be used as Dictionary keys or switch exhaustively without extra conformances; the storage key string must be stable and unique per host to avoid collisions between providers.

**Options:**
- A) Use kSecAttrAccount = host, kSecAttrService = bundleID + '.webdav' — separate Keychain item per host, no string interpolation in the primary key
- B) Flatten to string key 'webdav.<host>' and 'smb.<host>' — simple but requires sanitizing host for special characters
- C) Store all WebDAV passwords in a single Keychain item as JSON-encoded [host: password] dictionary

**Answer:**
Use kSecAttrAccount = host, kSecAttrService = bundleID + '.webdav' — separate Keychain item per host, no string interpolation in the primary key

## Question 5
What VReaderError / ErrorCode should be thrown when a key is not found (load on missing key)?

*Context:* The spec says errors go through VReaderError with ErrorCode.authentication, but 'not found' is semantically different from 'authentication failed' — callers like GeminiService need to distinguish 'key never set' from 'Keychain access denied' to show the correct recovery UI.

**Options:**
- A) Single ErrorCode.authentication for all Keychain failures — callers check OSStatus via associated value
- B) Two distinct cases: ErrorCode.authentication for access-denied/corrupt, ErrorCode.notFound (new sub-case) for missing key
- C) Return nil / Optional instead of throwing for missing-key case; throw only for actual Keychain errors

**Answer:**
Return nil / Optional instead of throwing for missing-key case; throw only for actual Keychain errors

## Question 6
Should Keychain items persist after app deletion and reinstall, or be cleared on first launch after reinstall?

*Context:* iOS preserves Keychain items across app deletion by default; this means a reinstalled app silently inherits old OAuth tokens and API keys, which may be revoked or belong to a different account — the spec lists this as an open question but it affects first-launch UX and security posture.

**Options:**
- A) Preserve across reinstall — default iOS behavior, user does not need to re-enter credentials
- B) Clear all Keychain items on first launch after reinstall — detect via a UserDefaults sentinel flag set at first run
- C) Clear only OAuth tokens on reinstall, preserve WebDAV/SMB passwords and Gemini API key

**Answer:**
Clear all Keychain items on first launch after reinstall — detect via a UserDefaults sentinel flag set at first run
