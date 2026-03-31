# Tasks: error-code-system

## Stage 1: Core Error Type System + Migration

- [ ] Read and audit `Vreader/ErrorCode.swift` — record all existing cases and call sites → mental model for migration
- [ ] Read and audit `App/Vreader/Vreader/ErrorCode.swift` — record all existing cases and call sites → mental model for migration
- [ ] Scan all Swift files in `Vreader/` for references to old `ErrorCode` type → patch list
- [ ] Scan all Swift files in `App/Vreader/Vreader/` for references to old `ErrorCode` type → patch list
- [ ] Create `App/Vreader/Vreader/AppError.swift` with `AppError` struct (`Error`, `LocalizedError`, `@unchecked Sendable`) containing `code`, `description`, `recoveryHint`, `underlyingError` → `App/Vreader/Vreader/AppError.swift`
- [ ] Define `ErrorCode` enum (`Equatable`, `Hashable`, `Sendable`) with all 8 category cases inside `App/Vreader/Vreader/AppError.swift` → `App/Vreader/Vreader/AppError.swift`
- [ ] Define `FileSystemError` enum (`Equatable`, `Hashable`, `Sendable`) with cases: `.fileNotFound`, `.permissionDenied`, `.bookmarkStale`, `.diskFull` → `App/Vreader/Vreader/AppError.swift`
- [ ] Define `NetworkError` enum (`Equatable`, `Hashable`, `Sendable`) with cases: `.unavailable`, `.timeout`, `.invalidResponse`, `.sslError` → `App/Vreader/Vreader/AppError.swift`
- [ ] Define `CloudProviderError` enum (`Equatable`, `Hashable`, `Sendable`) with cases: `.authenticationFailed`, `.quotaExceeded`, `.fileConflict`, `.providerUnavailable` → `App/Vreader/Vreader/AppError.swift`
- [ ] Define `AIServiceError` enum (`Equatable`, `Hashable`, `Sendable`) with cases: `.apiKeyMissing`, `.rateLimitExceeded`, `.modelUnavailable`, `.responseParsingFailed` → `App/Vreader/Vreader/AppError.swift`
- [ ] Define `StoreKitError` enum (`Equatable`, `Hashable`, `Sendable`) with cases: `.purchaseFailed`, `.verificationFailed`, `.productNotFound`, `.subscriptionExpired` → `App/Vreader/Vreader/AppError.swift`
- [ ] Define `SyncError` enum (`Equatable`, `Hashable`, `Sendable`) with cases: `.conflictUnresolved`, `.pendingChangesLost`, `.clockSkewDetected`, `.recordNotFound` → `App/Vreader/Vreader/AppError.swift`
- [ ] Define `ParsingError` enum (`Equatable`, `Hashable`, `Sendable`) with cases: `.unsupportedFormat`, `.corruptedData`, `.encodingFailed`, `.pageRenderFailed` → `App/Vreader/Vreader/AppError.swift`
- [ ] Define `AuthError` enum (`Equatable`, `Hashable`, `Sendable`) with cases: `.tokenExpired`, `.oauthFlowCancelled`, `.keychainAccessFailed`, `.credentialsInvalid` → `App/Vreader/Vreader/AppError.swift`
- [ ] Implement `analyticsCode: String` computed var on `AppError` returning strictly `"category.caseName"` with no dynamic values → `App/Vreader/Vreader/AppError.swift`
- [ ] Implement `LocalizedError` conformance: `errorDescription` → `description`, `recoverySuggestion` → `recoveryHint` → `App/Vreader/Vreader/AppError.swift`
- [ ] Implement factory method `AppError.fileNotFound(path:)` → `App/Vreader/Vreader/AppError.swift`
- [ ] Implement factory method `AppError.networkUnavailable()` → `App/Vreader/Vreader/AppError.swift`
- [ ] Implement factory method `AppError.premiumRequired(feature:)` → `App/Vreader/Vreader/AppError.swift`
- [ ] Implement factory method `AppError.timeout(service:)` → `App/Vreader/Vreader/AppError.swift`
- [ ] Add `// TODO: replace with L10n.*` comment to every `description` and `recoveryHint` string literal → `App/Vreader/Vreader/AppError.swift`
- [ ] Mirror complete `AppError.swift` content to `Vreader/AppError.swift` → `Vreader/AppError.swift`
- [ ] Delete `App/Vreader/Vreader/ErrorCode.swift` → file removed
- [ ] Delete `Vreader/ErrorCode.swift` → file removed
- [ ] Update `App/Vreader/Vreader/AppThemeError.swift` — replace old `ErrorCode` references with new `AppError`/`ErrorCode` → `App/Vreader/Vreader/AppThemeError.swift`
- [ ] Update `App/Vreader/Vreader/BookImporter.swift` — replace old `ErrorCode` references → `App/Vreader/Vreader/BookImporter.swift`
- [ ] Update `App/Vreader/Vreader/WebDAVProvider.swift` — replace old `ErrorCode` references → `App/Vreader/Vreader/WebDAVProvider.swift`
- [ ] Update `App/Vreader/Vreader/iCloudProvider.swift` — replace old `ErrorCode` references → `App/Vreader/Vreader/iCloudProvider.swift`
- [ ] Update `App/Vreader/Vreader/CloudProviderManager.swift` — replace old `ErrorCode` references → `App/Vreader/Vreader/CloudProviderManager.swift`
- [ ] Update `App/Vreader/Vreader/CloudProviderProtocol.swift` — replace old `ErrorCode` references → `App/Vreader/Vreader/CloudProviderProtocol.swift`
- [ ] Update `Vreader/WebDAVProvider.swift` — replace old `ErrorCode` references → `Vreader/WebDAVProvider.swift`
- [ ] Update `Vreader/iCloudProvider.swift` — replace old `ErrorCode` references → `Vreader/iCloudProvider.swift`
- [ ] Update `Vreader/CloudProviderManager.swift` — replace old `ErrorCode` references → `Vreader/CloudProviderManager.swift`
- [ ] Update `Vreader/CloudProviderProtocol.swift` — replace old `ErrorCode` references → `Vreader/CloudProviderProtocol.swift`
- [ ] Audit remaining files (`DownloadTask.swift`, `EPUBParser.swift`, `VreaderApp.swift`, `ReaderView.swift`, etc.) in both roots for any residual `ErrorCode` references and patch → respective files
- [ ] Create `AI_NOTES.md` documenting: `@unchecked Sendable` rationale for `AppError`, L10n exemption for string constants, `check_refs.py` exclusion scope, migration summary → `AI_NOTES.md`

## Stage 2: Unit Tests

- [ ] Replace `App/Vreader/VreaderTests/VreaderTests.swift` with full test suite for `AppError` → `App/Vreader/VreaderTests/VreaderTests.swift`
- [ ] Replace `VreaderTests/VreaderTests.swift` with full test suite for `AppError` → `VreaderTests/VreaderTests.swift`
- [ ] Write test: `fileNotFound(path:)` factory → `code == .fileSystem(.fileNotFound)` → test files
- [ ] Write test: `networkUnavailable()` factory → `code == .network(.unavailable)` → test files
- [ ] Write test: `premiumRequired(feature:)` factory → correct `StoreKitError` case → test files
- [ ] Write test: `timeout(service:)` factory → `code == .network(.timeout)` → test files
- [ ] Write test: `analyticsCode` for all 8 categories matches `^[a-zA-Z]+\.[a-zA-Z]+$` pattern → test files
- [ ] Write test: `errorDescription` equals `description` field → test files
- [ ] Write test: `recoverySuggestion` equals `recoveryHint` field → test files
- [ ] Write test: `ErrorCode` equality — same cases equal, different cases not equal → test files
- [ ] Write test: `ErrorCode` as `Dictionary` key (hashability) → test files
- [ ] Write test: `AppError` passable across actor boundary without Swift 6 concurrency warning → test files