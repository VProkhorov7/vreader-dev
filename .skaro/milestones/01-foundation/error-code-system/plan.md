## plan.md

## Stage 1: Core Error Type System + Migration

**Goal:** Replace both existing `ErrorCode.swift` files with a single `AppError.swift` containing the complete `AppError` struct, `ErrorCode` enum with all 8 nested category enums, all factory methods, `analyticsCode`, `Sendable` conformances, and `LocalizedError` conformance. Simultaneously update all call sites in both project roots (`Vreader/` and `App/Vreader/Vreader/`) that reference the old `ErrorCode`.

**Depends on:** none

**Inputs:**
- `Vreader/ErrorCode.swift` (to be deleted)
- `App/Vreader/Vreader/ErrorCode.swift` (to be deleted)
- `App/Vreader/Vreader/AppThemeError.swift` (potential call site)
- `App/Vreader/Vreader/BookImporter.swift` (potential call site)
- `App/Vreader/Vreader/WebDAVProvider.swift` (potential call site)
- `App/Vreader/Vreader/iCloudProvider.swift` (potential call site)
- `App/Vreader/Vreader/CloudProviderManager.swift` (potential call site)
- `App/Vreader/Vreader/CloudProviderProtocol.swift` (potential call site)
- `Vreader/WebDAVProvider.swift` (potential call site)
- `Vreader/iCloudProvider.swift` (potential call site)
- `Vreader/CloudProviderManager.swift` (potential call site)
- `Vreader/CloudProviderProtocol.swift` (potential call site)
- Specification: error-code-system
- Architecture document
- Constitution

**Outputs:**
- `App/Vreader/Vreader/AppError.swift` ← **new, primary**
- `Vreader/AppError.swift` ← **new, primary**
- `App/Vreader/Vreader/ErrorCode.swift` ← **deleted**
- `Vreader/ErrorCode.swift` ← **deleted**
- `App/Vreader/Vreader/AppThemeError.swift` ← updated call sites
- `App/Vreader/Vreader/BookImporter.swift` ← updated call sites
- `App/Vreader/Vreader/WebDAVProvider.swift` ← updated call sites
- `App/Vreader/Vreader/iCloudProvider.swift` ← updated call sites
- `App/Vreader/Vreader/CloudProviderManager.swift` ← updated call sites
- `App/Vreader/Vreader/CloudProviderProtocol.swift` ← updated call sites
- `Vreader/WebDAVProvider.swift` ← updated call sites
- `Vreader/iCloudProvider.swift` ← updated call sites
- `Vreader/CloudProviderManager.swift` ← updated call sites
- `Vreader/CloudProviderProtocol.swift` ← updated call sites
- `AI_NOTES.md` ← new, documents L10n exemption and migration notes

**DoD:**
- [ ] `AppError` is a `struct` conforming to `Error`, `LocalizedError`, `Sendable`
- [ ] `ErrorCode` is an `enum` conforming to `Equatable`, `Hashable`, `Sendable`
- [ ] All 8 nested category enums present: `FileSystemError`, `NetworkError`, `CloudProviderError`, `AIServiceError`, `StoreKitError`, `SyncError`, `ParsingError`, `AuthError` — each conforming to `Equatable`, `Hashable`, `Sendable`
- [ ] Each category has the exact case set from FR-03
- [ ] `AppError.code: ErrorCode`, `.description: String`, `.recoveryHint: String`, `.underlyingError: Error?` all present
- [ ] `LocalizedError.errorDescription` returns `description`; `recoverySuggestion` returns `recoveryHint`
- [ ] Factory methods present and correct: `AppError.fileNotFound(path:)`, `AppError.networkUnavailable()`, `AppError.premiumRequired(feature:)`, `AppError.timeout(service:)`
- [ ] `analyticsCode` is a computed `var` returning strictly `"category.caseName"` with no dynamic runtime values
- [ ] Every `description` and `recoveryHint` string literal has `// TODO: replace with L10n.*` comment
- [ ] Both old `ErrorCode.swift` files are absent from the project
- [ ] No remaining references to the old `ErrorCode` type in any Swift file
- [ ] `AI_NOTES.md` documents the L10n exemption and `check_refs.py` exclusion rationale
- [ ] Project compiles in Swift 6 mode without warnings related to this change

**Risks:**
- Old `ErrorCode.swift` may have cases not visible from the file tree alone — call sites in files like `DownloadTask.swift`, `EPUBParser.swift`, `VreaderApp.swift` may reference it; all must be audited and patched in the same pass
- Two parallel project roots (`Vreader/` and `App/Vreader/Vreader/`) require identical changes — divergence would cause `check_refs.py` failures
- `underlyingError: Error?` stored property on a `Sendable` struct requires `@unchecked Sendable` or the underlying error must itself be `Sendable`; Swift 6 will flag this — must be handled with `@unchecked Sendable` on `AppError` with a documented rationale in `AI_NOTES.md`
- `analyticsCode` for `premiumRequired(feature:)` factory — the `feature` parameter must NOT appear in `analyticsCode`; the case must map to a static string like `"storeKit.purchaseFailed"` or a dedicated case

---

## Stage 2: Unit Tests

**Goal:** Write unit tests in `VreaderTests.swift` (and its counterpart) covering: all factory methods, `analyticsCode` format validation for every category, `LocalizedError` surface, `Equatable`/`Hashable` on `ErrorCode`, and `Sendable` usage across a simulated actor boundary.

**Depends on:** Stage 1

**Inputs:**
- `App/Vreader/Vreader/AppError.swift`
- `Vreader/AppError.swift`
- `App/Vreader/VreaderTests/VreaderTests.swift`
- `VreaderTests/VreaderTests.swift`
- Specification acceptance criteria

**Outputs:**
- `App/Vreader/VreaderTests/VreaderTests.swift` ← replaced with full test suite
- `VreaderTests/VreaderTests.swift` ← replaced with full test suite

**DoD:**
- [ ] Test: `AppError.fileNotFound(path:)` produces `code == .fileSystem(.fileNotFound)`
- [ ] Test: `AppError.networkUnavailable()` produces `code == .network(.unavailable)`
- [ ] Test: `AppError.premiumRequired(feature:)` produces `code == .storeKit(.purchaseFailed)` (or the designated case)
- [ ] Test: `AppError.timeout(service:)` produces `code == .network(.timeout)`
- [ ] Test: `analyticsCode` for every category matches regex `^[a-zA-Z]+\.[a-zA-Z]+$` (no slashes, no spaces, no dynamic data)
- [ ] Test: `errorDescription` equals `description`; `recoverySuggestion` equals `recoveryHint`
- [ ] Test: `ErrorCode` equality — two identical codes are equal, two different codes are not
- [ ] Test: `ErrorCode` hashability — can be used as `Dictionary` key
- [ ] Test: `AppError` can be passed across an actor boundary without compiler warning (actor isolation test)
- [ ] All tests pass with `xcodebuild test`

**Risks:**
- Actor boundary test requires a concrete `actor` definition inside the test file — straightforward but must compile cleanly under Swift 6 strict concurrency
- `premiumRequired` factory case mapping needs to be consistent between Stage 1 implementation and Stage 2 test expectations

---

## Verify

```yaml
- name: Check old ErrorCode.swift deleted (App target)
  command: test ! -f App/Vreader/Vreader/ErrorCode.swift && echo "OK: deleted" || echo "FAIL: still exists"

- name: Check old ErrorCode.swift deleted (root target)
  command: test ! -f Vreader/ErrorCode.swift && echo "OK: deleted" || echo "FAIL: still exists"

- name: Check AppError.swift exists (App target)
  command: test -f App/Vreader/Vreader/AppError.swift && echo "OK" || echo "FAIL: missing"

- name: Check AppError.swift exists (root target)
  command: test -f Vreader/AppError.swift && echo "OK" || echo "FAIL: missing"

- name: Check no remaining references to old ErrorCode type
  command: grep -rn "ErrorCode\b" App/Vreader/Vreader/ Vreader/ --include="*.swift" | grep -v "AppError.swift" | grep -v "ErrorCode:" | grep -v "\.errorCode" || echo "OK: no stale references"

- name: Check analyticsCode format (no slashes, no spaces, dot-separated only)
  command: grep -n "analyticsCode" App/Vreader/Vreader/AppError.swift | grep -v "var analyticsCode" | grep -v "//" || echo "OK"

- name: Check TODO L10n comments present
  command: grep -c "TODO: replace with L10n" App/Vreader/Vreader/AppError.swift

- name: Check AI_NOTES.md exists
  command: test -f AI_NOTES.md && echo "OK" || echo "FAIL: missing"

- name: Check Sendable conformances present
  command: grep -c "Sendable" App/Vreader/Vreader/AppError.swift

- name: Build App target
  command: xcodebuild build -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination "platform=iOS Simulator,name=iPhone 16" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5

- name: Run unit tests
  command: xcodebuild test -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination "platform=iOS Simulator,name=iPhone 16" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```